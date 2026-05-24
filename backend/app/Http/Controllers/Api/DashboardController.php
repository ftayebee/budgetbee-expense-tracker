<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\TransactionResource;
use App\Support\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    use ApiResponse;

    public function __invoke(Request $request)
    {
        $user = $request->user();
        $tx = $user->transactions();
        $monthTx = $user->transactions()->whereMonth('transaction_date', now()->month)->whereYear('transaction_date', now()->year);

        $categorySummary = fn (string $type) => $user->transactions()
            ->select('category_id', DB::raw('sum(amount) as total'))
            ->where('type', $type)
            ->with('category')
            ->groupBy('category_id')
            ->orderByDesc('total')
            ->limit(6)
            ->get()
            ->map(fn ($row) => ['category' => $row->category?->name, 'total' => (float) $row->total]);

        return $this->success([
            'total_income' => (float) (clone $tx)->where('type', 'income')->sum('amount'),
            'total_expense' => (float) (clone $tx)->where('type', 'expense')->sum('amount'),
            'current_balance' => (float) $user->accounts()->sum('current_balance'),
            'accounts_balance' => (float) $user->accounts()->sum('current_balance'),
            'monthly_income' => (float) (clone $monthTx)->where('type', 'income')->sum('amount'),
            'monthly_expense' => (float) (clone $monthTx)->where('type', 'expense')->sum('amount'),
            'recent_transactions' => TransactionResource::collection($user->transactions()->with(['account', 'category', 'fromAccount', 'toAccount'])->latest('transaction_date')->limit(8)->get()),
            'expense_by_category' => $categorySummary('expense'),
            'income_by_category' => $categorySummary('income'),
        ]);
    }
}
