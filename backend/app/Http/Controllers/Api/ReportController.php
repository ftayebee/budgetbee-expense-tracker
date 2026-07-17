<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\AccountResource;
use App\Http\Resources\BudgetResource;
use App\Http\Resources\TransactionResource;
use App\Support\ApiResponse;
use Carbon\CarbonImmutable;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    use ApiResponse;

    public function monthlySummary(Request $request)
    {
        $dateSql = $this->dateParts();

        return $this->success($request->user()->transactions()
            ->selectRaw("{$dateSql['year']} as year, {$dateSql['month']} as month, type, sum(amount) as total")
            ->whereIn('type', ['income', 'expense'])
            ->groupBy('year', 'month', 'type')
            ->orderBy('year')->orderBy('month')->get());
    }

    public function categorySummary(Request $request)
    {
        return $this->success($request->user()->transactions()
            ->select('category_id', 'type', DB::raw('sum(amount) as total'))
            ->whereIn('type', ['income', 'expense'])
            ->with('category')->groupBy('category_id', 'type')->orderByDesc('total')->get());
    }

    public function accountSummary(Request $request)
    {
        return $this->success($request->user()->accounts()
            ->withSum(['transactions as income' => fn ($q) => $q->where('type', 'income')], 'amount')
            ->withSum(['transactions as expense' => fn ($q) => $q->where('type', 'expense')], 'amount')
            ->get());
    }

    public function yearlySummary(Request $request)
    {
        $dateSql = $this->dateParts();

        return $this->success($request->user()->transactions()
            ->selectRaw("{$dateSql['year']} as year, type, sum(amount) as total")
            ->whereIn('type', ['income', 'expense'])
            ->groupBy('year', 'type')->orderBy('year')->get());
    }

    public function analytics(Request $request)
    {
        $validated = $request->validate([
            'from' => ['required', 'date'],
            'to' => ['required', 'date', 'after_or_equal:from'],
            'type' => ['nullable', 'in:income,expense'],
            'category_id' => ['nullable', 'integer'],
            'account_id' => ['nullable', 'integer'],
            'payment_method' => ['nullable', 'string', 'max:80'],
        ]);

        $from = CarbonImmutable::parse($validated['from'])->startOfDay();
        $to = CarbonImmutable::parse($validated['to'])->endOfDay();
        abort_if($from->diffInDays($to) > 730, 422, 'Analytics ranges are limited to two years.');

        $days = $from->diffInDays($to) + 1;
        $comparisonTo = $from->subDay()->endOfDay();
        $comparisonFrom = $comparisonTo->subDays($days - 1)->startOfDay();

        $base = $request->user()->transactions()
            ->with(['account', 'category', 'fromAccount', 'toAccount'])
            ->whereIn('type', ['income', 'expense']);

        foreach (['type', 'category_id', 'account_id', 'payment_method'] as $filter) {
            if (! empty($validated[$filter])) {
                $base->where($filter, $validated[$filter]);
            }
        }

        $current = (clone $base)
            ->whereBetween('transaction_date', [$from->toDateString(), $to->toDateString()])
            ->orderBy('transaction_date')
            ->orderBy('id')
            ->get();
        $comparison = (clone $base)
            ->whereBetween('transaction_date', [$comparisonFrom->toDateString(), $comparisonTo->toDateString()])
            ->orderBy('transaction_date')
            ->orderBy('id')
            ->get();

        $budgets = $request->user()->budgets()
            ->with('category')
            ->whereBetween('year', [$from->year, $to->year])
            ->get();

        $balanceTransactions = $request->user()->transactions();
        $accountBalances = $request->user()->accounts();
        if (! empty($validated['account_id'])) {
            $accountId = (int) $validated['account_id'];
            $balanceTransactions->where(fn ($query) => $query
                ->where('account_id', $accountId)
                ->orWhere('from_account_id', $accountId)
                ->orWhere('to_account_id', $accountId));
            $accountBalances->whereKey($accountId);
        }
        $balanceChange = function ($transactions, callable $dateScope) use ($validated): float {
            $scoped = $dateScope(clone $transactions);
            $change = (float) (clone $scoped)->where('type', 'income')->sum('amount')
                - (float) (clone $scoped)->where('type', 'expense')->sum('amount');
            if (! empty($validated['account_id'])) {
                $accountId = (int) $validated['account_id'];
                $change += (float) (clone $scoped)->where('type', 'transfer')->where('to_account_id', $accountId)->sum('amount')
                    - (float) (clone $scoped)->where('type', 'transfer')->where('from_account_id', $accountId)->sum('amount');
            }
            return $change;
        };
        $openingBalance = (float) $accountBalances->sum('opening_balance')
            + $balanceChange($balanceTransactions, fn ($query) => $query->whereDate('transaction_date', '<', $from->toDateString()));
        $closingBalance = $openingBalance
            + $balanceChange($balanceTransactions, fn ($query) => $query->whereBetween('transaction_date', [$from->toDateString(), $to->toDateString()]));

        return $this->success([
            'from' => $from->toDateString(),
            'to' => $to->toDateString(),
            'comparison_from' => $comparisonFrom->toDateString(),
            'comparison_to' => $comparisonTo->toDateString(),
            'opening_balance' => round($openingBalance, 2),
            'closing_balance' => round($closingBalance, 2),
            'transactions' => TransactionResource::collection($current),
            'comparison_transactions' => TransactionResource::collection($comparison),
            'accounts' => AccountResource::collection($request->user()->accounts()->orderBy('name')->get()),
            'budgets' => BudgetResource::collection($budgets),
        ]);
    }

    private function dateParts(): array
    {
        if (config('database.default') === 'sqlite') {
            return ['year' => "strftime('%Y', transaction_date)", 'month' => "strftime('%m', transaction_date)"];
        }

        return ['year' => 'YEAR(transaction_date)', 'month' => 'MONTH(transaction_date)'];
    }
}
