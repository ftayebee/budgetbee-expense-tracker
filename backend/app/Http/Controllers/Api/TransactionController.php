<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\TransactionRequest;
use App\Http\Resources\TransactionResource;
use App\Models\Transaction;
use App\Services\TransactionService;
use App\Support\ApiResponse;
use Illuminate\Http\Request;

class TransactionController extends Controller
{
    use ApiResponse;

    public function __construct(private TransactionService $service) {}

    public function index(Request $request)
    {
        $query = $request->user()->transactions()->with(['account', 'category', 'fromAccount', 'toAccount']);

        foreach (['type', 'category_id', 'account_id', 'payment_method'] as $filter) {
            if ($request->filled($filter)) {
                $query->where($filter, $request->$filter);
            }
        }
        if ($request->filled('from')) {
            $query->whereDate('transaction_date', '>=', $request->from);
        }
        if ($request->filled('to')) {
            $query->whereDate('transaction_date', '<=', $request->to);
        }
        if ($request->filled('min_amount')) {
            $query->where('amount', '>=', (float) $request->min_amount);
        }
        if ($request->filled('max_amount')) {
            $query->where('amount', '<=', (float) $request->max_amount);
        }
        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(fn ($q) => $q->where('title', 'like', "%{$search}%")->orWhere('note', 'like', "%{$search}%"));
        }

        $this->applySort($query, $request->input('sort', 'date_desc'));

        $perPage = min(max((int) $request->input('per_page', 30), 1), 100);
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

    public function update(TransactionRequest $request, Transaction $transaction)
    {
        abort_unless($transaction->user_id === $request->user()->id, 404);

        return $this->success(new TransactionResource($this->service->update($transaction, $request->validated() + ['user_id' => $request->user()->id])), 'Transaction updated');
    }

    public function destroy(Request $request, Transaction $transaction)
    {
        abort_unless($transaction->user_id === $request->user()->id, 404);
        $this->service->delete($transaction);

        return $this->success(null, 'Transaction deleted');
    }
}
