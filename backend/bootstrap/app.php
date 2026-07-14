<?php

use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Middleware\HandleCors;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->api(prepend: [
            HandleCors::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->render(function (ValidationException $e, Request $request) {
            if ($request->is('api/*')) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $e->errors(),
                ], 422);
            }
        });

        $exceptions->render(function (Throwable $e, Request $request) {
            if (! $request->is('api/*')) {
                return null;
            }

            [$status, $message] = match (true) {
                $e instanceof AuthenticationException => [401, 'Unauthenticated.'],
                $e instanceof AuthorizationException => [403, 'This action is unauthorized.'],
                $e instanceof ModelNotFoundException => [404, 'Resource not found.'],
                $e instanceof HttpExceptionInterface => [$e->getStatusCode(), $e->getMessage() ?: 'Request failed.'],
                default => [500, null],
            };

            // Never leak internal error details or stack traces to API clients.
            if ($status === 500) {
                report($e);
                $message = 'Something went wrong';
            }

            return response()->json([
                'success' => false,
                'message' => $message,
                'errors' => [],
            ], $status);
        });
    })->create();
