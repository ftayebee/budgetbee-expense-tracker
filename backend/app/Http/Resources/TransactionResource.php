<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TransactionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'type' => $this->type,
            'amount' => (float) $this->amount,
            'transaction_date' => $this->transaction_date?->toDateString(),
            'note' => $this->note,
            'payment_method' => $this->payment_method,
            'attachment' => $this->attachment,
            'account' => new AccountResource($this->whenLoaded('account')),
            'category' => new CategoryResource($this->whenLoaded('category')),
            'from_account' => new AccountResource($this->whenLoaded('fromAccount')),
            'to_account' => new AccountResource($this->whenLoaded('toAccount')),
            'created_at' => $this->created_at?->toISOString(),
        ];
    }
}
