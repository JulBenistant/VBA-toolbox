% This scripts loads data from the TACHE MERE done by stefano Palminteri
% It then performs the inversion of the DATA using a model in which
% probabilities rather than expected outcome are learned

clear all
close all


%-----NOTES on how file is organized
% session1 = training session
% session2-3 = test sessions
%-- DATA
% column 1 = index of session
% column 2 = index of trial
% column 3 = condition (1=Gain (1), 2=Neutral (0), 3=Loss (-1))
% column 4 = checktime
% column 5 = 1=Go, -1=NoGo 
% column 6 = choice (1=correct, -1=incorrect)
% (correct = most rewarded option in cond=1 | less punished option in cond=3)
% colonne 7 = feedback (cond 1 : 1 = 1 , -1=0 | cond 3, 1=0, -1=-1)
% colonne 8 = reaction time, (millisec if Go, 0 if NoGo)
% colonne 9 = number of hesitations



%----------- DO THE INVERSION FOR ALL SUBJECTS

controls1=[1001:1015 1103 1106 1108 1109]; % controles ag้s (Stefano, tache m๊re)
INVERSION = cell(1,length(controls1)); % where results for each subjects will be saved
SESSIONS = [2,3]; % the two training sessions

i_s =0; % index of subject
for i_subject = controls1
    
i_s = i_s+1;
%----------- FIRST : Loading the data & formating for inversion

root = 'C:\Users\vincent.adam\Desktop\Vincent ADAM\Matlab\Demo_toolbox\Data\Data_tache_mere\VINCENT\'; % location of data folder
subfolder = 'CONTROLS_1\';

%-- LOADING THE TWO SESSIONS --%

Y = [];
U = [];

for i_session = SESSIONS; % index of session

filename = ['ILtestSub',num2str(i_subject),'Session',num2str(i_session)]; % as saved by stefano
file_root = [root, subfolder, filename]; % position of file on hard-drive

load(file_root); % loading file


%---- Formating data for further inversion

%-----NOTES on how data should be formated
% y: binary choice 
% u: 
%   - subject choice (binary)
%   - outcome category (binary)
% 
% outcomes values must be specified in options:
%   - inG.o1;
%   - inG.o2;


%=== second, let's consider the two conditions together : gains and loss.
cond = data(:,3); % vector of conditions
i_cond1 = find(cond==1); % indices of trial where condition is 1 (gain)
i_cond3 = find(cond==3); % indices of trial where condition is 3 (loss)

% outputs
y1 = data(i_cond1,6)'>0; % binary choice (0: correct, 1:incorrect)
y3 = data(i_cond3,6)'>0; % binary choice (0: correct, 1:incorrect)
% experimenter data
u1 = [y1;... % binary choice (0: correct, 1:incorrect)
     data(i_cond1,7)'>0]; % binary outcome (0: best, 1:worst)
u3 = [y3;... % binary choice (0: correct, 1:incorrect)
     data(i_cond3,7)'>0]; % binary outcome (0: best, 1:worst)

Y = [Y;y1;y3]; 
U = [U;u1;u3]; 

end


%%
%----------- SECOND : Performing the inversion with probability learning
Ntrials = size(Y,2);

% evolution, observation and feedback functions
f_fname = @f_OpLearn_2p; % evolution function for the learning of probability
g_fname = @g_softmax_EU_2p; % softmax decision based on probabilities of outcome 1
% parameters : 1=inverse temperature, 2= asymmetry parameter in prospect
% theory
h_fname = @h_choice_outcome_2p; % feedback is the outcome of the chosen action

% allocate feedback struture for simulations

% defining the utility function
u_fname = @u_prospect_theory; % handle of utility function
inG.u_fname = u_fname;
inG.o1 = 1;
inG.o2 = 0;

% simulation parameters % See  Mathys, Daunizeau et al. 2010 for a
% detailled description of parameters
inF.lev2 = 1; % remove 3rd level (volatility learning)
inF.kaub = 1.4;
inF.thub = 1;
inF.rf = -1;
inG.respmod = 'taylor';

% choose initial conditions
x0 = repmat([0.5;0;0;1;log(4)],2*2*2,1); % 

dim = struct('n',2*2*2*5,... (2 sessions)*(2 conditions)*(2 probas)% number of hidden states in the probability learning model
             'n_theta',3,...
             'n_phi',2,...
             'p',2,...
             'n_sess',2*2,...
             'n_ps',2*5,...
             'p_ps',1,...
             'n_data_ps',2);
         
Nsessions = 4;
in_sessions = struct();
in_sessions.f_fname = f_fname; % name of function for each session
in_sessions.g_fname = g_fname;
in_sessions.dim = dim;
in_sessions.ind.theta =  ones(Nsessions,1)*[1:3]; % index of param for sessions
in_sessions.ind.phi =   ones(Nsessions,1)*[1:2]; % index of param for sessions
in_sessions.binomial = 1;

in_sessions.sess(1).inG = inG;
in_sessions.sess(1).inG.o1 = 1; % Best option is o1
in_sessions.sess(1).inG.o2 = 0;
in_sessions.sess(2).inG = inG;
in_sessions.sess(2).inG.o1 = 0; % Best option is o1
in_sessions.sess(2).inG.o2 = -1;
in_sessions.sess(3).inG = inG;
in_sessions.sess(3).inG.o1 = 1; % Best option is o1
in_sessions.sess(3).inG.o2 = 0;
in_sessions.sess(4).inG = inG;
in_sessions.sess(4).inG.o1 = 0; % Best option is o1
in_sessions.sess(4).inG.o2 = -1;

in_sessions.inF = inF;


IsYout = 0*Y;

priors.muPhi = zeros(dim.n_phi,1);
priors.muTheta = [0;-4;0];
priors.muX0 = x0;
priors.SigmaPhi = 1e2*eye(dim.n_phi);
priors.SigmaTheta = 1e2*eye(dim.n_theta);
priors.SigmaX0 = 0e1*eye(dim.n);
priors.a_alpha = Inf;
priors.b_alpha = 0;

options.priors = priors;
options.binomial = 1;
options.inF = inF;
options.inG = inG;
options.skipf = zeros(1,Ntrials);
options.skipf(1) = 1; % apply identity mapping from x0 to x1.
options.isYout = zeros(1,Ntrials);
in_sessions.options = options;

[posterior,out] = inversion_multiple_sessions(in_sessions, Y, U, IsYout, priors);


% Saving data after inversion
clear results;
results.posterior = posterior;
results.out = out;
results.in_sessions = in_sessions;
results.Y = Y;
results.U = U;
results.IsYout = IsYout;
results.priors = priors;
results.i_subject = i_subject; % real index of subject (as in stefano's study)

INVERSION{i_s}.results = results;


end 

save sujet2p INVERSION
