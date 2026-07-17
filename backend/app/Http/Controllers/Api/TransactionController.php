<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\TransactionRequest;
use App\Http\Resources\TransactionResource;
use App\Models\Transaction;
use App\Services\TransactionService;
use App\Support\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;
use Throwable;

class TransactionController extends Controller
{
    use ApiResponse;

    public function __construct(private TransactionService $service) {}

    public function index(Request $request)
    {
        $validated = $request->validate([
            'type' => ['nullable', 'in:income,expense,transfer'],
            'category_id' => ['nullable', 'integer'],
            'account_id' => ['nullable', 'integer'],
            'payment_method' => ['nullable', 'string', 'max:255'],
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date', 'after_or_equal:from'],
            'min_amount' => ['nullable', 'numeric', 'min:0'],
            'max_amount' => ['nullable', 'numeric', 'min:0'],
            'sort' => ['nullable', 'in:date_desc,date_asc,amount_desc,amount_asc'],
            'search' => ['nullable', 'string', 'max:255'],
            'page' => ['nullable', 'integer', 'min:1'],
            'per_page' => ['nullable', 'integer', 'between:1,100'],
        ]);
        if (isset($validated['min_amount'], $validated['max_amount'])
            && (float) $validated['min_amount'] > (float) $validated['max_amount']) {
            throw ValidationException::withMessages([
                'max_amount' => ['The maximum amount must be greater than or equal to the minimum amount.'],
            ]);
        }
        $query = $request->user()->transactions()->with(['account', 'category', 'fromAccount', 'toAccount']);

        foreach (['type', 'category_id', 'payment_method'] as $filter) {
            if (! empty($validated[$filter])) {
                $query->where($filter, $validated[$filter]);
            }
        }
        if (! empty($validated['account_id'])) {
            $accountId = (int) $validated['account_id'];
            $query->where(fn ($accountQuery) => $accountQuery
                ->where('account_id', $accountId)
                ->orWhere('from_account_id', $accountId)
                ->orWhere('to_account_id', $accountId));
        }
        if (! empty($validated['from'])) {
            $query->whereDate('transaction_date', '>=', $validated['from']);
        }
        if (! empty($validated['to'])) {
            $query->whereDate('transaction_date', '<=', $validated['to']);
        }
        if (isset($validated['min_amount'])) {
            $query->where('amount', '>=', (float) $validated['min_amount']);
        }
        if (isset($validated['max_amount'])) {
            $query->where('amount', '<=', (float) $validated['max_amount']);
        }
        if (! empty($validated['search'])) {
            $search = addcslashes($validated['search'], '%_\\');
            $query->where(fn($q) => $q->where('title', 'like', "%{$search}%")->orWhere('note', 'like', "%{$search}%"));
        }

        $this->applySort($query, $validated['sort'] ?? 'date_desc');

        $perPage = (int) ($validated['per_page'] ?? 30);
        $paginated = $query->paginate($perPage);

        return $this->success([
            'data' => TransactionResource::collection($paginated),
            'meta' => [
                'current_page' => $paginated->currentPage(),
                'last_page' => $paginated->lastPage(),
                'per_page' => $paginated->perPage(),
                'total' => $paginated->total(),
            ],
        ]);
    }

    private function applySort($query, string $sort): void
    {
        match ($sort) {
            'date_asc' => $query->orderBy('transaction_date')->orderBy('id'),
            'amount_desc' => $query->orderByDesc('amount')->orderByDesc('id'),
            'amount_asc' => $query->orderBy('amount')->orderBy('id'),
            default => $query->latest('transaction_date')->latest('id'),
        };
    }

    public function store(TransactionRequest $request)
    {
        return $this->success(new TransactionResource($this->service->create($request->validated() + ['user_id' => $request->user()->id])), 'Transaction created', 201);
    }

    public function show(Request $request, Transaction $transaction)
    {
        abort_unless($transaction->user_id === $request->user()->id, 404);

        return $this->success(new TransactionResource($transaction->load(['account', 'category', 'fromAccount', 'toAccount'])));
    }

    public function update(
        TransactionRequest $request,
        Transaction $transaction
    ) {
        $user = $request->user();

        Log::info('Transaction update requested', [
            'transaction_id' => $transaction->id,
            'transaction_user_id' => $transaction->user_id,
            'authenticated_user_id' => $user?->id,
            'request_method' => $request->method(),
            'request_ip' => $request->ip(),
        ]);

        if ((int) $transaction->user_id !== (int) $user->id) {
            Log::warning('Unauthorized transaction update attempt', [
                'transaction_id' => $transaction->id,
                'transaction_user_id' => $transaction->user_id,
                'authenticated_user_id' => $user->id,
                'request_ip' => $request->ip(),
            ]);

            abort(404);
        }

        try {
            $validatedData = $request->validated();

            Log::debug('Transaction update validation passed', [
                'transaction_id' => $transaction->id,
                'authenticated_user_id' => $user->id,
                'validated_fields' => array_keys($validatedData),
                'request_method' => $request->method(),
            ]);

            $updatedTransaction = $this->service->update(
                $transaction,
                $validatedData + [
                    'user_id' => $user->id,
                ]
            );

            Log::info('Transaction updated successfully', [
                'transaction_id' => $updatedTransaction->id,
                'authenticated_user_id' => $user->id,
            ]);

            return $this->success(
                new TransactionResource($updatedTransaction),
                'Transaction updated',
                200
            );
        } catch (Throwable $exception) {
            Log::error('Transaction update failed', [
                'transaction_id' => $transaction->id,
                'authenticated_user_id' => $user->id,
                'exception' => $exception::class,
                'message' => $exception->getMessage(),
                'file' => $exception->getFile(),
                'line' => $exception->getLine(),
                'trace' => $exception->getTraceAsString(),
            ]);

            throw $exception;
        }
    }

    public function destroy(Request $request, Transaction $transaction)
    {
        $user = $request->user();

        Log::info('Transaction delete requested', [
            'transaction_id' => $transaction->id,
            'transaction_user_id' => $transaction->user_id,
            'authenticated_user_id' => $user?->id,
            'request_method' => $request->method(),
            'request_url' => $request->fullUrl(),
            'request_ip' => $request->ip(),
        ]);

        if (!$user || (int) $transaction->user_id !== (int) $user->id) {
            Log::warning('Unauthorized transaction delete attempt', [
                'transaction_id' => $transaction->id,
                'transaction_user_id' => $transaction->user_id,
                'authenticated_user_id' => $user?->id,
                'request_ip' => $request->ip(),
            ]);

            abort(404);
        }

        try {
            $transactionId = $transaction->id;

            Log::debug('Transaction delete service starting', [
                'transaction_id' => $transactionId,
                'authenticated_user_id' => $user->id,
            ]);

            $this->service->delete($transaction);

            Log::info('Transaction deleted successfully', [
                'transaction_id' => $transactionId,
                'authenticated_user_id' => $user->id,
            ]);

            return $this->success(
                null,
                'Transaction deleted',
                200
            );
        } catch (Throwable $exception) {
            Log::error('Transaction delete failed', [
                'transaction_id' => $transaction->id,
                'authenticated_user_id' => $user->id,
                'exception' => $exception::class,
                'message' => $exception->getMessage(),
                'file' => $exception->getFile(),
                'line' => $exception->getLine(),
                'trace' => $exception->getTraceAsString(),
            ]);

            throw $exception;
        }
    }
}
