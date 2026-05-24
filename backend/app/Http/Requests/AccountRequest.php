<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class AccountRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'type' => ['required', 'in:cash,bank,mobile_banking,card,other'],
            'opening_balance' => [$this->isMethod('post') ? 'required' : 'sometimes', 'numeric', 'min:0'],
            'color' => ['nullable', 'string', 'max:24'],
            'icon' => ['nullable', 'string', 'max:48'],
            'is_default' => ['sometimes', 'boolean'],
        ];
    }
}
