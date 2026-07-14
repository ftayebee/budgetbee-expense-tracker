<?php

namespace App\Providers;

use Illuminate\Auth\Notifications\ResetPassword;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // This is an API-only backend with a mobile client, so the password-reset
        // notification cannot link to a `password.reset` web route (there isn't one).
        // Build a deep link the mobile app handles, plus the raw token for manual entry.
        ResetPassword::createUrlUsing(function (object $notifiable, string $token) {
            $frontend = config('app.frontend_url', config('app.url'));

            return rtrim($frontend, '/').'/reset-password?token='.$token.'&email='.urlencode($notifiable->getEmailForPasswordReset());
        });
    }
}
