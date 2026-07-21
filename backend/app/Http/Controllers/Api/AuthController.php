<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\AuthLoginRequest;
use App\Http\Requests\AuthRegisterRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Support\ApiResponse;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Password;
use Illuminate\Validation\Rules\Password as PasswordRule;
use Throwable;

class AuthController extends Controller
{
    use ApiResponse;

    public function register(AuthRegisterRequest $request)
    {
        $context = $this->registrationLogContext($request);
        Log::info('Registration request received', $context);

        try {
            [$user, $token] = DB::transaction(function () use ($request) {
                $user = User::create($request->validated());
                try {
                    $token = $user->createToken('android')->plainTextToken;
                } catch (Throwable $exception) {
                    Log::error('Registration token generation failed', $this->registrationLogContext($request) + [
                        'user_id' => $user->id,
                        'exception' => $exception::class,
                        'exception_message' => $exception->getMessage(),
                    ]);
                    report($exception);
                    throw $exception;
                }

                return [$user, $token];
            });
        } catch (QueryException $exception) {
            $duplicateField = $this->duplicateRegistrationField($exception);
            $context = $this->registrationLogContext($request) + [
                'exception' => $exception::class,
                'sql_state' => $exception->errorInfo[0] ?? null,
                'driver_code' => $exception->errorInfo[1] ?? null,
                'duplicate_field' => $duplicateField,
            ];

            if ($duplicateField !== null) {
                Log::warning('Duplicate registration blocked by database', $context);
                $message = $duplicateField === 'phone'
                    ? 'This phone number is already registered.'
                    : 'This email address is already registered.';

                return $this->error(
                    'Registration failed',
                    [$duplicateField => [$message]],
                    409
                );
            }

            Log::error('Registration database failure', $context);
            report($exception);

            return $this->error('Registration failed', [], 500);
        } catch (Throwable $exception) {
            Log::error('Unexpected registration failure', $this->registrationLogContext($request) + [
                'exception' => $exception::class,
                'exception_message' => $exception->getMessage(),
            ]);
            report($exception);

            return $this->error('Registration failed', [], 500);
        }

        Log::info('Registration successful', $context + ['user_id' => $user->id]);

        return $this->success(['user' => new UserResource($user), 'token' => $token], 'Registration successful', 201);
    }

    private function duplicateRegistrationField(QueryException $exception): ?string
    {
        $sqlState = (string) ($exception->errorInfo[0] ?? '');
        $driverCode = (string) ($exception->errorInfo[1] ?? '');
        if ($sqlState !== '23000' && ! in_array($driverCode, ['19', '1062', '2067'], true)) {
            return null;
        }

        $details = mb_strtolower($exception->getMessage());
        if (str_contains($details, 'phone')) {
            return 'phone';
        }
        if (str_contains($details, 'email')) {
            return 'email';
        }

        return null;
    }

    private function registrationLogContext(Request $request): array
    {
        return [
            'email_hash' => $request->filled('email')
                ? hash('sha256', mb_strtolower(trim((string) $request->input('email'))))
                : null,
            'phone_hash' => $request->filled('phone')
                ? hash('sha256', trim((string) $request->input('phone')))
                : null,
            'platform' => $request->header('X-Client-Platform'),
            'user_agent' => mb_substr((string) $request->userAgent(), 0, 500),
        ];
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
