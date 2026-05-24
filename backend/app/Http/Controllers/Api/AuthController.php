<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\AuthLoginRequest;
use App\Http\Requests\AuthRegisterRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Support\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    use ApiResponse;

    public function register(AuthRegisterRequest $request)
    {
        $user = User::create($request->validated());
        $token = $user->createToken('android')->plainTextToken;

        return $this->success(['user' => new UserResource($user), 'token' => $token], 'Registration successful', 201);
    }

    public function login(AuthLoginRequest $request)
    {
        $user = User::where('email', $request->email)->first();
        if (! $user || ! Hash::check($request->password, $user->password)) {
            return $this->error('Invalid credentials', ['email' => ['The provided credentials are incorrect.']], 422);
        }

        return $this->success(['user' => new UserResource($user), 'token' => $user->createToken('android')->plainTextToken], 'Login successful');
    }

    public function me(Request $request)
    {
        return $this->success(new UserResource($request->user()));
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()?->delete();
        return $this->success(null, 'Logged out successfully');
    }
}
