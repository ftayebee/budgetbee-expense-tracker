<?php

namespace App\Services;

use App\Models\GoalContribution;
use App\Models\SavingsGoal;
use Illuminate\Support\Facades\DB;

class SavingsGoalService
{
    public function contribute(SavingsGoal $goal, array $data): GoalContribution
    {
        return DB::transaction(function () use ($goal, $data) {
            $contribution = $goal->contributions()->create([
                'amount' => $data['amount'],
                'note' => $data['note'] ?? null,
                'contributed_at' => $data['contributed_at'] ?? now()->toDateString(),
            ]);

            $this->recalculate($goal);

            return $contribution;
        });
    }

    public function removeContribution(GoalContribution $contribution): void
    {
        DB::transaction(function () use ($contribution) {
            $goal = $contribution->goal;
            $contribution->delete();
            $this->recalculate($goal);
        });
    }

    /**
     * Recompute the goal's current amount from its contributions and update the
     * status so it always reflects the source-of-truth contribution records.
     */
    private function recalculate(SavingsGoal $goal): void
    {
        $total = (float) $goal->contributions()->sum('amount');
        $goal->current_amount = $total;

        // Never auto-move a cancelled goal; otherwise reflect completion state.
        if ($goal->status !== 'cancelled') {
            $goal->status = $total >= (float) $goal->target_amount && $total > 0
                ? 'completed'
                : 'active';
        }

        $goal->save();
    }
}
