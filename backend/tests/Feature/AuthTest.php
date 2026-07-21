<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Log;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_a_user_can_register_and_receives_a_token(): void
    {
        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'Jane Doe',
            'email' => 'jane@example.com',
            'password' => 'secret123',
            'password_confirmation' => 'secret123',
        ]);

        $response->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.user.email', 'jane@example.com')
            ->assertJsonStructure(['data' => ['token', 'user' => ['id', 'name', 'email']]]);

        $this->assertDatabaseHas('users', ['email' => 'jane@example.com']);
    }

    public function test_registration_requires_a_unique_email(): void
    {
        User::factory()->create(['email' => 'taken@example.com']);

        $this->postJson('/api/v1/auth/register', [
            'name' => 'Jane',
            'email' => 'taken@example.com',
            'password' => 'secret123',
            'password_confirmation' => 'secret123',
        ])->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonPath('message', 'Validation failed')
            ->assertJsonPath('errors.email.0', 'The email has already been taken.');
    }

    public function test_registration_validation_failure_is_logged_without_credentials(): void
    {
        Log::spy();

        $this->withHeaders([
            'User-Agent' => 'BudgetBee Android test',
            'X-Client-Platform' => 'Android 8.1',
        ])->postJson('/api/v1/auth/register', [
            'name' => '',
            'email' => 'invalid',
            'password' => 'secret123',
            'password_confirmation' => 'different',
        ])->assertUnprocessable()
            ->assertJsonStructure([
                'success',
                'message',
                'errors' => ['name', 'email', 'password'],
            ]);

        Log::shouldHaveReceived('warning')
            ->once()
            ->withArgs(function (string $message, array $context): bool {
                return $message === 'Registration validation failed'
                    && $context['platform'] === 'Android 8.1'
                    && $context['user_agent'] === 'BudgetBee Android test'
                    && ! array_key_exists('password', $context)
                    && ! array_key_exists('password_confirmation', $context);
            });
    }

    public function test_registration_requires_password_confirmation(): void
    {
        $this->postJson('/api/v1/auth/register', [
            'name' => 'Jane',
            'email' => 'jane@example.com',
            'password' => 'secret123',
            'password_confirmation' => 'different',
        ])->assertStatus(422)->assertJsonValidationErrors('password');
    }

    public function test_registration_normalizes_and_rejects_duplicate_phone(): void
    {
        $payload = [
            'name' => 'Jane',
            'email' => 'jane@example.com',
            'phone' => '+880 1712-345678',
            'password' => 'secret123',
            'password_confirmation' => 'secret123',
        ];

        $this->postJson('/api/v1/auth/register', $payload)
            ->assertCreated()
            ->assertJsonPath('data.user.phone', '+8801712345678');

        $this->postJson('/api/v1/auth/register', array_merge($payload, [
            'email' => 'another@example.com',
            'phone' => '+880 (1712) 345678',
        ]))->assertUnprocessable()
            ->assertJsonPath('success', false)
            ->assertJsonPath('errors.phone.0', 'The phone number has already been taken.');

        $this->assertDatabaseCount('users', 1);
    }

    public function test_successful_registration_is_logged_without_token_or_password(): void
    {
        Log::spy();

        $this->postJson('/api/v1/auth/register', [
            'name' => 'Jane',
            'email' => 'jane@example.com',
            'password' => 'secret123',
            'password_confirmation' => 'secret123',
        ])->assertCreated();

        Log::shouldHaveReceived('info')
            ->withArgs(fn (string $message, array $context): bool =>
                $message === 'Registration request received'
                && ! array_key_exists('password', $context)
                && ! array_key_exists('token', $context));
        Log::shouldHaveReceived('info')
            ->withArgs(fn (string $message, array $context): bool =>
                $message === 'Registration successful'
                && isset($context['user_id'])
                && ! array_key_exists('password', $context)
                && ! array_key_exists('token', $context));
    }

    public function test_a_user_can_login_with_valid_credentials(): void
    {
        User::factory()->create([
            'email' => 'john@example.com',
            'password' => bcrypt('secret123'),
        ]);

        $this->postJson('/api/v1/auth/login', [
            'email' => 'john@example.com',
            'password' => 'secret123',
        ])->assertOk()->assertJsonStructure(['data' => ['token', 'user']]);
    }

    public function test_login_fails_with_invalid_credentials(): void
    {
        User::factory()->create([
            'email' => 'john@example.com',
            'password' => bcrypt('secret123'),
        ]);

        $this->postJson('/api/v1/auth/login', [
            'email' => 'john@example.com',
            'password' => 'wrong-password',
        ])->assertStatus(422)->assertJsonPath('success', false);
    }

    public function test_me_endpoint_requires_authentication(): void
    {
        $this->getJson('/api/v1/auth/me')->assertUnauthorized();
    }

    public function test_authenticated_user_can_fetch_profile_and_logout(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        $this->withToken($token)->getJson('/api/v1/auth/me')
            ->assertOk()->assertJsonPath('data.id', $user->id);

        $this->withToken($token)->postJson('/api/v1/auth/logout')->assertOk();

        // Logout revokes the access token. (A second HTTP round-trip in the same
        // test can't verify this: the auth guard memoizes the resolved user across
        // sub-requests, so we assert the token row itself was deleted.)
        $this->assertDatabaseCount('personal_access_tokens', 0);
    }
}
