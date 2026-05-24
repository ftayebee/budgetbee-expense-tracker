<?php

namespace App\Services;

use App\Models\Account;
use App\Models\Transaction as MoneyTransaction;
use Illuminate\Support\Facades\DB;

class TransactionService
{
    public function create(array $data): MoneyTransaction
    {
        return DB::transaction(function () use ($data) {
            $transaction = MoneyTransaction::create($data);
            $transaction->load(['account', 'category', 'fromAccount', 'toAccount']);
            $this->applyTransaction($transaction);

            return $transaction;
        });
    }

    public function update(MoneyTransaction $transaction, array $data): MoneyTransaction
    {
        return DB::transaction(function () use ($transaction, $data) {
            $old = $transaction->fresh(['account', 'fromAccount', 'toAccount']);
            $this->reverseTransaction($old);

            $transaction->update($data);
            $transaction->refresh()->load(['account', 'category', 'fromAccount', 'toAccount']);
            $this->applyTransaction($transaction);

            return $transaction;
        });
    }

    public function delete(MoneyTransaction $transaction): void
    {
        DB::transaction(function () use ($transaction) {
            $transaction->load(['account', 'fromAccount', 'toAccount']);
            $this->reverseTransaction($transaction);
            $transaction->delete();
        });
    }

    private function applyTransaction(MoneyTransaction $transaction): void
    {
        if ($transaction->type === 'transfer') {
            $this->applyTransfer($transaction->fromAccount, $transaction->toAccount, (float) $transaction->amount);
            return;
        }

        $this->apply($transaction->account, $transaction->type, (float) $transaction->amount);
    }

    private function reverseTransaction(MoneyTransaction $transaction): void
    {
        if ($transaction->type === 'transfer') {
            $this->applyTransfer($transaction->toAccount, $transaction->fromAccount, (float) $transaction->amount);
            return;
        }

        $this->reverse($transaction->account, $transaction->type, (float) $transaction->amount);
    }

    private function applyTransfer(Account $from, Account $to, float $amount): void
    {
        $from->decrement('current_balance', $amount);
        $to->increment('current_balance', $amount);
    }

    private function apply(Account $account, string $type, float $amount): void
    {
        $account->increment('current_balance', $type === 'income' ? $amount : -$amount);
    }

    private function reverse(Account $account, string $type, float $amount): void
    {
        $account->increment('current_balance', $type === 'income' ? -$amount : $amount);
    }
}
