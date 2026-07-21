<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Log;

class AnalyticsReportRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'from' => ['required', 'date'],
            'to' => ['required', 'date', 'after_or_equal:from'],
            'type' => ['nullable', 'in:income,expense'],
            'category_id' => ['nullable', 'integer'],
            'account_id' => ['nullable', 'integer'],
            'payment_method' => ['nullable', 'string', 'max:80'],
        ];
    }

    protected function failedValidation(Validator $validator): void
    {
        Log::warning('Reports API validation failed', [
            'user_id' => optional($this->user())->id,
            'fields' => array_keys($validator->errors()->toArray()),
            'filters' => $this->safeFilters(),
            'user_agent' => mb_substr((string) $this->userAgent(), 0, 500),
        ]);

        parent::failedValidation($validator);
    }

    private function safeFilters(): array
    {
        return $this->only([
            'from',
            'to',
            'type',
            'category_id',
            'account_id',
            'payment_method',
        ]);
    }
}
