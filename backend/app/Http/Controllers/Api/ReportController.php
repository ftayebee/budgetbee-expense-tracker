<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\ApiResponse;
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

    private function dateParts(): array
    {
        if (config('database.default') === 'sqlite') {
            return ['year' => "strftime('%Y', transaction_date)", 'month' => "strftime('%m', transaction_date)"];
        }

        return ['year' => 'YEAR(transaction_date)', 'month' => 'MONTH(transaction_date)'];
    }
}
