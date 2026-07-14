<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SavingsGoalResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $target = (float) $this->target_amount;
        $current = (float) $this->current_amount;
        $remaining = max($target - $current, 0);

        return [
            'id' => $this->id,
            'name' => $this->name,
            'target_amount' => $target,
            'current_amount' => $current,
            'remaining_amount' => $remaining,
            'progress' => $target > 0 ? round(min($current / $target, 1) * 100, 1) : 0.0,
            'target_date' => $this->target_date?->toDateString(),
            'monthly_contribution_needed' => $this->monthlyContributionNeeded($remaining),
            'account_id' => $this->account_id,
            'account' => new AccountResource($this->whenLoaded('account')),
            'icon' => $this->icon,
            'color' => $this->color,
            'status' => $this->status,
            'contributions' => GoalContributionResource::collection($this->whenLoaded('contributions')),
            'created_at' => $this->created_at?->toISOString(),
        ];
    }

    /**
     * Amount the user needs to set aside each month to hit the target by the
     * target date. Null when there is no deadline or the goal is already met.
     */
    private function monthlyContributionNeeded(float $remaining): ?float
    {
        if (! $this->target_date || $remaining <= 0) {
            return null;
        }

        $months = max(now()->startOfMonth()->diffInMonths($this->target_date->copy()->startOfMonth()), 1);

        return round($remaining / $months, 2);
    }
}
