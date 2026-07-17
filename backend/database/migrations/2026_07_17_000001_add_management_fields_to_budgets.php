<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('budgets', function (Blueprint $table) {
            $table->string('name')->nullable()->after('category_id');
            $table->date('start_date')->nullable()->after('period');
            $table->date('end_date')->nullable()->after('start_date');
            $table->unsignedTinyInteger('alert_threshold')->default(80)->after('end_date');
        });
    }

    public function down(): void
    {
        Schema::table('budgets', function (Blueprint $table) {
            $table->dropColumn(['name', 'start_date', 'end_date', 'alert_threshold']);
        });
    }
};
