<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    use HasFactory;

    protected $fillable = ['user_id', 'account_id', 'category_id', 'from_account_id', 'to_account_id', 'title', 'type', 'amount', 'transaction_date', 'note', 'payment_method', 'attachment'];

    protected $casts = [
        'amount' => 'decimal:2',
        'transaction_date' => 'date',
    ];

    public function user() { return $this->belongsTo(User::class); }
    public function account() { return $this->belongsTo(Account::class); }
    public function category() { return $this->belongsTo(Category::class); }
    public function fromAccount() { return $this->belongsTo(Account::class, 'from_account_id'); }
    public function toAccount() { return $this->belongsTo(Account::class, 'to_account_id'); }
}
