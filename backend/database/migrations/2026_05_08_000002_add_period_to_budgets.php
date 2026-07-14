<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Guarded so a fresh install (where the base migration already defines the
        // column) does not fail with a duplicate-column error.
        Schema::table('budgets', function (Blueprint $table) {
            if (! Schema::hasColumn('budgets', 'period')) {
                $table->string('period', 16)->default('monthly')->after('amount');
            }
        });
    }

    public function down(): void
    {
        Schema::table('budgets', function (Blueprint $table) {
            if (Schema::hasColumn('budgets', 'period')) {
                $table->dropColumn('period');
            }
        });
    }
};
