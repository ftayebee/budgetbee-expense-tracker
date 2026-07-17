<?php

namespace App\Http\Requests;

use App\Models\Category;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Validator;

class BudgetRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    protected function prepareForValidation(): void
    {
        $year = (int) ($this->input('year') ?: now()->year);
        $month = (int) ($this->input('month') ?: now()->month);
        $this->merge([
            'name' => $this->input('name') ?: 'Category Budget',
            'start_date' => $this->input('start_date') ?: sprintf('%04d-%02d-01', $year, $month),
            'alert_threshold' => $this->input('alert_threshold') ?: 80,
            'month' => $month,
            'year' => $year,
        ]);
    }

    public function rules(): array
    {
        return [
            'category_id' => ['required', 'integer'],
            'name' => ['required', 'string', 'max:120'],
            'amount' => ['required', 'numeric', 'min:0.01'],
            'period' => ['required', 'in:daily,weekly,monthly,yearly'],
            'start_date' => ['required', 'date'],
            'end_date' => ['nullable', 'date', 'after_or_equal:start_date'],
            'alert_threshold' => ['required', 'integer', 'between:1,100'],
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
