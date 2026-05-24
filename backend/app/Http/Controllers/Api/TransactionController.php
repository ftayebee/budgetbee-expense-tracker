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
        $query = $request->user()->transactions()->with(['account', 'category', 'fromAccount', 'toAccount'])->latest('transaction_date')->latest();
        foreach (['type', 'category_id', 'account_id'] as $filter) {
            if ($request->filled($filter)) {
                $query->where($filter, $request->$filter);
            }
        }
        if ($request->filled('from')) $query->whereDate('transaction_date', '>=', $request->from);
        if ($request->filled('to')) $query->whereDate('transaction_date', '<=', $request->to);
        if ($request->filled('search')) {
            $query->where(fn ($q) => $q->where('title', 'like', "%{$request->search}%")->orWhere('note', 'like', "%{$request->search}%"));
        }

        return $this->success(TransactionResource::collection($query->paginate(30)));
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
