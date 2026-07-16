<?php

namespace App\Support;

trait ApiResponse
{
    protected function success(mixed $data = null, string $message = 'Operation successful', int $status = 200)
    {
        return response()->json(['success' => true, 'message' => $message, 'data' => $data], $status);
    }

    protected function error(string $message = 'Request failed', mixed $errors = [], int $status = 400)
    {
        return response()->json([
            'success' => false,
            'message' => $message,
            'errors' => is_array($errors) && array_is_list($errors) ? (object) [] : $errors,
        ], $status);
    }
}
