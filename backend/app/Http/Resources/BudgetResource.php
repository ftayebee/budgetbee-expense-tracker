<?php

namespace App\Http\Resources;

use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BudgetResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $query = Transaction::query()
            ->where('user_id', $this->user_id)
            ->where('category_id', $this->category_id)
            ->where('type', 'expense');
        if ($this->start_date) {
            $query->whereDate('transaction_date', '>=', $this->start_date);
            if ($this->end_date) {
                $query->whereDate('transaction_date', '<=', $this->end_date);
            }
        } else {
            $query->whereMonth('transaction_date', $this->month)
                ->whereYear('transaction_date', $this->year);
        }
        $spent = $query->sum('amount');

        return [
            'id' => $this->id,
            'category' => new CategoryResource($this->whenLoaded('category')),
            'name' => $this->name ?? (($this->category?->name ?? 'Category') . ' Budget'),
            'amount' => (float) $this->amount,
            'spent' => (float) $spent,
            'remaining' => (float) $this->amount - (float) $spent,
            'period' => $this->period ?? 'monthly',
            'start_date' => $this->start_date?->toDateString(),
            'end_date' => $this->end_date?->toDateString(),
            'alert_threshold' => (int) ($this->alert_threshold ?? 80),
            'month' => $this->month,
            'year' => $this->year,
        ];
    }
}
