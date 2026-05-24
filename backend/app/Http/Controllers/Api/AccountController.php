<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\AccountRequest;
use App\Http\Resources\AccountResource;
use App\Models\Account;
use App\Support\ApiResponse;
use Illuminate\Http\Request;

class AccountController extends Controller
{
    use ApiResponse;

    public function index(Request $request)
    {
        return $this->success(AccountResource::collection($request->user()->accounts()->latest()->get()));
    }

    public function store(AccountRequest $request)
    {
        $data = $request->validated();
        $data['user_id'] = $request->user()->id;
        $data['current_balance'] = $data['opening_balance'];
        if (($data['is_default'] ?? false) === true) {
            $request->user()->accounts()->update(['is_default' => false]);
        }

        return $this->success(new AccountResource(Account::create($data)), 'Account created', 201);
    }

    public function show(Request $request, Account $account)
    {
        abort_unless($account->user_id === $request->user()->id, 404);
        return $this->success(new AccountResource($account));
    }

    public function update(AccountRequest $request, Account $account)
    {
        abort_unless($account->user_id === $request->user()->id, 404);
        $data = $request->validated();
        if (($data['is_default'] ?? false) === true) {
            $request->user()->accounts()->whereKeyNot($account->id)->update(['is_default' => false]);
        }
        unset($data['opening_balance']);
        $account->update($data);

        return $this->success(new AccountResource($account->refresh()), 'Account updated');
    }

    public function destroy(Request $request, Account $account)
    {
        abort_unless($account->user_id === $request->user()->id, 404);
        if ($account->transactions()->exists()) {
            return $this->error('Account has transactions and cannot be deleted.', [], 409);
        }
        $account->delete();

        return $this->success(null, 'Account deleted');
    }
}
