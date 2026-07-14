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
use Illuminate\Support\Facades\Password;
use Illuminate\Validation\Rules\Password as PasswordRule;

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

    public function forgotPassword(Request $request)
    {
        $request->validate(['email' => ['required', 'email']]);

        // Fires the password reset notification (mailer). We always return a generic
        // success message to avoid leaking which emails are registered.
        Password::sendResetLink($request->only('email'));

        return $this->success(null, 'If an account exists for that email, a password reset link has been sent.');
    }

    public function resetPassword(Request $request)
    {
        $request->validate([
            'token' => ['required', 'string'],
            'email' => ['required', 'email'],
            'password' => ['required', 'confirmed', PasswordRule::min(8)],
        ]);

        $status = Password::reset(
            $request->only('email', 'password', 'password_confirmation', 'token'),
            function (User $user, string $password) {
                $user->forceFill(['password' => $password])->save();
                // Revoke existing API tokens so a compromised session cannot persist
                // after a password reset.
                $user->tokens()->delete();
            }
        );

        if ($status !== Password::PASSWORD_RESET) {
            return $this->error(__($status), ['email' => [__($status)]], 422);
        }

        return $this->success(null, 'Password has been reset. Please log in.');
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
