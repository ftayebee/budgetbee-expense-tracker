<?php

use App\Http\Controllers\Api\AccountController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BudgetController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\SavingsGoalController;
use App\Http\Controllers\Api\TransactionController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::prefix('auth')->group(function () {
        // Throttle unauthenticated auth endpoints to slow brute-force / enumeration.
        Route::middleware('throttle:10,1')->group(function () {
            Route::post('register', [AuthController::class, 'register']);
            Route::post('login', [AuthController::class, 'login']);
            Route::post('forgot-password', [AuthController::class, 'forgotPassword']);
            Route::post('reset-password', [AuthController::class, 'resetPassword']);
        });
        Route::middleware('auth:sanctum')->group(function () {
            Route::post('logout', [AuthController::class, 'logout']);
            Route::get('me', [AuthController::class, 'me']);
        });
    });

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('dashboard', DashboardController::class);
        Route::apiResource('accounts', AccountController::class);
        Route::apiResource('categories', CategoryController::class);
        Route::apiResource('transactions', TransactionController::class);
        Route::apiResource('budgets', BudgetController::class);

        Route::apiResource('savings-goals', SavingsGoalController::class)
            ->parameters(['savings-goals' => 'savingsGoal']);
        Route::post('savings-goals/{savingsGoal}/contributions', [SavingsGoalController::class, 'contribute']);
        Route::delete('savings-goals/{savingsGoal}/contributions/{contribution}', [SavingsGoalController::class, 'removeContribution']);

        Route::get('reports/monthly-summary', [ReportController::class, 'monthlySummary']);
        Route::get('reports/category-summary', [ReportController::class, 'categorySummary']);
        Route::get('reports/account-summary', [ReportController::class, 'accountSummary']);
        Route::get('reports/yearly-summary', [ReportController::class, 'yearlySummary']);
        Route::get('reports/analytics', [ReportController::class, 'analytics']);

        Route::get('profile', [ProfileController::class, 'show']);
        Route::put('profile', [ProfileController::class, 'update']);
        Route::put('profile/password', [ProfileController::class, 'password']);
    });
});
