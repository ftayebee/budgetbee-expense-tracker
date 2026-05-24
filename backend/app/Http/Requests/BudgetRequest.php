<?php

namespace App\Http\Requests;

use App\Models\Category;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

class BudgetRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'category_id' => ['required', 'integer'],
            'amount' => ['required', 'numeric', 'min:0.01'],
            'period' => ['required', 'in:daily,weekly,monthly,yearly'],
            'month' => ['required', 'integer', 'between:1,12'],
            'year' => ['required', 'integer', 'between:2000,2100'],
        ];
    }

    public function after(): array
    {
        return [function (Validator $validator) {
            $userId = $this->user()->id;
            if (! Category::where('id', $this->category_id)->where('type', 'expense')->where(function ($q) use ($userId) {
                $q->whereNull('user_id')->orWhere('user_id', $userId);
            })->exists()) {
                $validator->errors()->add('category_id', 'The selected expense category is invalid.');
            }
        }];
    }
}
