<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\SavingsGoalRequest;
use App\Http\Resources\SavingsGoalResource;
use App\Models\GoalContribution;
use App\Models\SavingsGoal;
use App\Services\SavingsGoalService;
use App\Support\ApiResponse;
use Illuminate\Http\Request;

class SavingsGoalController extends Controller
{
    use ApiResponse;

    public function __construct(private SavingsGoalService $service) {}

    public function index(Request $request)
    {
        $goals = $request->user()->savingsGoals()
            ->with('account')
            ->latest()
            ->get();

        return $this->success(SavingsGoalResource::collection($goals));
    }

    public function store(SavingsGoalRequest $request)
    {
        $goal = $request->user()->savingsGoals()->create($request->validated());

        // refresh() pulls DB-applied defaults (status, current_amount) onto the model.
        return $this->success(new SavingsGoalResource($goal->refresh()->load('account')), 'Savings goal created', 201);
    }

    public function show(Request $request, SavingsGoal $savingsGoal)
    {
        $this->authorizeGoal($request, $savingsGoal);

        return $this->success(new SavingsGoalResource($savingsGoal->load(['account', 'contributions'])));
    }

    public function update(SavingsGoalRequest $request, SavingsGoal $savingsGoal)
    {
        $this->authorizeGoal($request, $savingsGoal);
        $savingsGoal->update($request->validated());

        return $this->success(new SavingsGoalResource($savingsGoal->refresh()->load('account')), 'Savings goal updated');
    }

    public function destroy(Request $request, SavingsGoal $savingsGoal)
    {
        $this->authorizeGoal($request, $savingsGoal);
        $savingsGoal->delete();

        return $this->success(null, 'Savings goal deleted');
    }

    public function contribute(Request $request, SavingsGoal $savingsGoal)
    {
        $this->authorizeGoal($request, $savingsGoal);

        $data = $request->validate([
            'amount' => ['required', 'numeric', 'min:0.01'],
            'note' => ['nullable', 'string', 'max:255'],
            'contributed_at' => ['nullable', 'date'],
        ]);

        $this->service->contribute($savingsGoal, $data);

        return $this->success(
            new SavingsGoalResource($savingsGoal->refresh()->load(['account', 'contributions'])),
            'Contribution added',
            201
        );
    }

    public function removeContribution(Request $request, SavingsGoal $savingsGoal, GoalContribution $contribution)
    {
        $this->authorizeGoal($request, $savingsGoal);
        abort_unless($contribution->savings_goal_id === $savingsGoal->id, 404);

        $this->service->removeContribution($contribution);

        return $this->success(
            new SavingsGoalResource($savingsGoal->refresh()->load(['account', 'contributions'])),
            'Contribution removed'
        );
    }

    private function authorizeGoal(Request $request, SavingsGoal $goal): void
    {
        abort_unless($goal->user_id === $request->user()->id, 404);
    }
}
