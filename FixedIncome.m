%% Coupon Data
clc; clear all;

Coupondata = xlsread( 'Fixed (1).xlsx', 'Coupon Bonds');
CouponRate = Coupondata(:,1)/100;
CouponExpiry = datetime(Coupondata(:,2),'ConvertFrom','excel');
CouponPrice = Coupondata(:,3);
CouponMaturity = Coupondata(:,4);
SettleDate = datetime('16-Feb-2019');
SettleDate = repmat(SettleDate,length(CouponRate),1);
SettleDate1 = datetime('16-Feb-2019');
SettleDate1 = datenum(SettleDate1);

%% Zero Data
Zerodata = xlsread('Fixed (1).xlsx', 'Zero Bonds');
ZeroExpiry = datetime(Zerodata(:,2),'ConvertFrom','excel');
ZeroYields = Zerodata(:,3)/100;
ZeroMaturity = Zerodata(:,4);
ZeroPrice = Zerodata(:,5);
ZeroRate = Zerodata(:,1);

%% Coupon Yields
CouponYields = bndyield(CouponPrice, CouponRate, SettleDate, CouponExpiry);

%% Combined Data
AllMaturity = [ZeroMaturity;CouponMaturity];
AllExpiry = [ZeroExpiry;CouponExpiry];
AllYields = [ZeroYields;CouponYields];
AllSettle = [repmat('16-Feb-2019',length(AllMaturity),1)];
CouponRate =[ZeroRate;CouponRate];
Price = [ZeroPrice;CouponPrice];

% Sort Data
Alldata = [AllMaturity, datenum(AllExpiry), AllYields, datenum(AllSettle), CouponRate, Price];
Alldata = sortrows(Alldata,1);


%% Nelson Siegel Model

AllExpiry = datenum(AllExpiry);
Settle = datenum(AllSettle);
Instruments = [Settle Alldata(:,2) Alldata(:,6) Alldata(:,5)];
NSModel = IRFunctionCurve.fitNelsonSiegel('Zero',datenum('16-Feb-2019'),Instruments,'Basis', 3);

PlottingPoints = datenum('16-Feb-2019'):180:datenum('16-Feb-2050');
figure 
plot(PlottingPoints, getParYields(NSModel, PlottingPoints),'r')
hold on
scatter(Alldata(:,2),Alldata(:,3),'black')
datetick('x')
title('Nelson Spiegel Model')
xlabel('Time')
ylabel('Yield')
hold off 

%% Svensson Model

SvenssonModel = IRFunctionCurve.fitSvensson('Zero','16-Feb-2019',Instruments);

% create the plot
figure 
plot(PlottingPoints, getParYields(SvenssonModel, PlottingPoints),'g') 
hold on 
scatter(AllExpiry,AllYields,'black') 
datetick('x')
title('Svensson Model')
xlabel('Time')
ylabel('Yield')
legend({'Svensson Fitted Curve','Yields'},'location','best')

%% Spline Method

% Parameters chosen to be roughly similar to [4] below. % Attempt 1
L = 0.00000001;
S = 7.702;
mu = 5.667;
% 
lambdafun = @(t) exp(L - (L-S)*exp(-t/mu)); % Construct penalty function
t = 0:.1:25; % Construct data to plot penalty function
y = lambdafun(t);
figure
semilogy(t,y);
title('Penalty Function for VRP Approach')
ylabel('Penalty')
xlabel('Time')

VRPModel = IRFunctionCurve.fitSmoothingSpline('Zero',SettleDate1,Instruments,lambdafun);

% create the plot
figure 
plot(PlottingPoints, getParYields(VRPModel, PlottingPoints),'g') 
hold on 
scatter(AllExpiry,AllYields,'black') 
datetick('x')
title('Spline Model')
xlabel('Time')
ylabel('Yield')
legend({'Spline Fitted Curve','Yields'},'location','best')

%Attempt 2

options = fitoptions('Method','Smooth','SmoothingParam',0.01);
f = fit(AllExpiry,AllYields,'smooth',options); %potenial spline function
plot(f)

%Attempt 3 using toolbox!

cftool

%% Plot all on one graph

Comparision = figure;
plot(PlottingPoints, getParYields(NSModel, PlottingPoints),'r') 
hold on
plot(PlottingPoints, getParYields(SvenssonModel, PlottingPoints),'g')
plot(PlottingPoints, f.p.coefs(:,4), 'b')
hold off
