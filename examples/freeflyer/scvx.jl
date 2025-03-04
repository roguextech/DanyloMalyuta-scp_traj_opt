#= 6-Degree of Freedom free-flyer example using SCvx.

Sequential convex programming algorithms for trajectory optimization.
Copyright (C) 2021 Autonomous Controls Laboratory (University of Washington),
                   and Autonomous Systems Laboratory (Stanford University)

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <https://www.gnu.org/licenses/>. =#

using ECOS

include("common.jl")
include("../../utils/helper.jl")
include("../../core/problem.jl")
include("../../core/scvx.jl")
include("../../models/freeflyer.jl")

# :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# :: Trajectory optimization problem ::::::::::::::::::::::::::::::::::::::::::
# :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

N = 50

mdl = FreeFlyerProblem(N)
pbm = TrajectoryProblem(mdl)

define_problem!(pbm, :scvx)

# :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# :: SCvx algorithm parameters ::::::::::::::::::::::::::::::::::::::::::::::::
# :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

Nsub = 15
iter_max = 15
λ = 1e3
ρ_0 = 0.0
ρ_1 = 0.1
ρ_2 = 0.7
β_sh = 2.0
β_gr = 2.0
η_init = 1.0
η_lb = 1e-6
η_ub = 10.0
ε_abs = 0#1e-5
ε_rel = 0#0.01/100
feas_tol = 1e-3
q_tr = Inf
q_exit = Inf
solver = ECOS
solver_options = Dict("verbose"=>0)
pars = SCvxParameters(N, Nsub, iter_max, λ, ρ_0, ρ_1, ρ_2, β_sh, β_gr,
                      η_init, η_lb, η_ub, ε_abs, ε_rel, feas_tol, q_tr,
                      q_exit, solver, solver_options)

# :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# :: Solve trajectory generation problem ::::::::::::::::::::::::::::::::::::::
# :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

# Number of trials. All trials will give the same solution, but we need many to
# plot statistically meaningful timing results
num_trials = 50

sol_list = Vector{SCPSolution}(undef, num_trials)
history_list = Vector{SCPHistory}(undef, num_trials)

for trial = 1:num_trials
    local scvx = SCvxProblem(pars, pbm)
    @printf("Trial %d/%d\n", trial, num_trials)
    if trial>1
        # Suppress output
        real_stdout = stdout
        (rd, wr) = redirect_stdout()
    end
    sol_list[trial], history_list[trial] = scvx_solve(scvx)
    if trial>1
        redirect_stdout(real_stdout)
    end
end

# Save one solution instance - for plotting a single trial
sol = sol_list[end]
history = history_list[end]

# :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# :: Plot results :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

plot_trajectory_history(mdl, history)
plot_final_trajectory(mdl, sol)
plot_timeseries(mdl, sol)
plot_obstacle_constraints(mdl, sol)
plot_convergence(history_list, "freeflyer")
