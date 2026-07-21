<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Log;

class AuthRegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'phone' => ['nullable', 'string', 'max:32', 'unique:users,phone'],
            'password' => ['required', 'confirmed', 'min:8'],
        ];
    }

    protected function prepareForValidation(): void
    {
        $phone = trim((string) $this->input('phone', ''));
        $this->merge([
            'name' => trim((string) $this->input('name', '')),
            'email' => mb_strtolower(trim((string) $this->input('email', ''))),
            'phone' => $phone === ''
                ? null
                : preg_replace('/(?!^\+)[^\d]/', '', $phone),
        ]);
    }

    public function messages(): array
    {
        return [
            'email.unique' => 'The email has already been taken.',
            'phone.unique' => 'The phone number has already been taken.',
        ];
    }

    protected function failedValidation(Validator $validator): void
    {
        Log::warning('Registration validation failed', [
            'fields' => array_keys($validator->errors()->toArray()),
            'email_hash' => $this->filled('email')
                ? hash('sha256', mb_strtolower(trim((string) $this->input('email'))))
                : null,
            'phone_hash' => $this->filled('phone')
                ? hash('sha256', trim((string) $this->input('phone')))
                : null,
            'platform' => $this->header('X-Client-Platform'),
            'user_agent' => mb_substr((string) $this->userAgent(), 0, 500),
        ]);

        parent::failedValidation($validator);
    }
}
