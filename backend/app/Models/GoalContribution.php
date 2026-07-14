<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class GoalContribution extends Model
{
    use HasFactory;

    protected $fillable = ['savings_goal_id', 'amount', 'note', 'contributed_at'];

    protected $casts = [
        'amount' => 'decimal:2',
        'contributed_at' => 'date',
    ];

    public function goal()
    {
        return $this->belongsTo(SavingsGoal::class, 'savings_goal_id');
    }
}
