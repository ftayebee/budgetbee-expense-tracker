<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (DB::getDriverName() === 'mysql') {
            DB::statement('ALTER TABLE transactions MODIFY account_id BIGINT UNSIGNED NULL');
            DB::statement('ALTER TABLE transactions MODIFY category_id BIGINT UNSIGNED NULL');
            DB::statement("ALTER TABLE transactions MODIFY type ENUM('income','expense','transfer') NOT NULL");
        }

        // Guarded so a fresh install (where the base migration already defines these
        // columns) does not fail with a duplicate-column error.
        Schema::table('transactions', function (Blueprint $table) {
            if (! Schema::hasColumn('transactions', 'from_account_id')) {
                $table->foreignId('from_account_id')->nullable()->after('category_id')->constrained('accounts')->restrictOnDelete();
            }
            if (! Schema::hasColumn('transactions', 'to_account_id')) {
                $table->foreignId('to_account_id')->nullable()->after('from_account_id')->constrained('accounts')->restrictOnDelete();
            }
        });
    }

    public function down(): void
    {
        Schema::table('transactions', function (Blueprint $table) {
            if (Schema::hasColumn('transactions', 'to_account_id')) {
                $table->dropConstrainedForeignId('to_account_id');
            }
            if (Schema::hasColumn('transactions', 'from_account_id')) {
                $table->dropConstrainedForeignId('from_account_id');
            }
        });

        if (DB::getDriverName() === 'mysql') {
            DB::statement("ALTER TABLE transactions MODIFY type ENUM('income','expense') NOT NULL");
        }
    }
};
