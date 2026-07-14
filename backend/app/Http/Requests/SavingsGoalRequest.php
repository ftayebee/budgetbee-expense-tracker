<?php

namespace App\Http\Requests;

use App\Models\Account;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

class SavingsGoalRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'target_amount' => ['required', 'numeric', 'min:0.01'],
            'target_date' => ['nullable', 'date', 'after_or_equal:today'],
            'account_id' => ['nullable', 'integer'],
            'icon' => ['nullable', 'string', 'max:48'],
            'color' => ['nullable', 'string', 'max:24'],
            'status' => ['sometimes', 'in:active,completed,cancelled'],
        ];
    }

    public function after(): array
    {
        return [function (Validator $validator) {
            if ($this->filled('account_id')) {
                $owns = Account::where('id', $this->account_id)
                    ->where('user_id', $this->user()->id)
                    ->exists();
                if (! $owns) {
                    $validator->errors()->add('account_id', 'The selected account is invalid.');
                }
            }
        }];
    }
}
