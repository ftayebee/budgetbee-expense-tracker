<?php

namespace App\Http\Requests;

use App\Models\Account;
use App\Models\Category;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

class TransactionRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'account_id' => ['required_unless:type,transfer', 'nullable', 'integer'],
            'category_id' => ['required_unless:type,transfer', 'nullable', 'integer'],
            'from_account_id' => ['required_if:type,transfer', 'nullable', 'integer', 'different:to_account_id'],
            'to_account_id' => ['required_if:type,transfer', 'nullable', 'integer'],
            'title' => ['required', 'string', 'max:255'],
            'type' => ['required', 'in:income,expense,transfer'],
            'amount' => ['required', 'numeric', 'min:0.01'],
            'transaction_date' => ['required', 'date'],
            'note' => ['nullable', 'string'],
            'payment_method' => ['nullable', 'string', 'max:255'],
            'attachment' => ['nullable', 'string', 'max:255'],
        ];
    }

    public function after(): array
    {
        return [
            function (Validator $validator) {
                $userId = $this->user()->id;
                if ($this->type === 'transfer') {
                    $from = Account::where('id', $this->from_account_id)->where('user_id', $userId)->first();
                    if (! $from) {
                        $validator->errors()->add('from_account_id', 'The selected source account is invalid.');
                    }
                    if (! Account::where('id', $this->to_account_id)->where('user_id', $userId)->exists()) {
                        $validator->errors()->add('to_account_id', 'The selected destination account is invalid.');
                    }
                    if ($from && (float) $from->current_balance < (float) $this->amount) {
                        $validator->errors()->add('amount', 'Transfer amount exceeds the source account balance.');
                    }
                    return;
                }

                if (! Account::where('id', $this->account_id)->where('user_id', $userId)->exists()) {
                    $validator->errors()->add('account_id', 'The selected account is invalid.');
                }
                if (! Category::where('id', $this->category_id)->where('type', $this->type)->where(function ($q) use ($userId) {
                    $q->whereNull('user_id')->orWhere('user_id', $userId);
                })->exists()) {
                    $validator->errors()->add('category_id', 'The selected category is invalid.');
                }
            },
        ];
    }
}
