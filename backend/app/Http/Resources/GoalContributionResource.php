<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class GoalContributionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'amount' => (float) $this->amount,
            'note' => $this->note,
            'contributed_at' => $this->contributed_at?->toDateString(),
            'created_at' => $this->created_at?->toISOString(),
        ];
    }
}
