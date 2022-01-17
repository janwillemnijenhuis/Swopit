version 14

mata:
/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       MANUAL INPUT      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

/*                           generate artificial covariates                                 */


// number of observations
n = 500	//0000

//generating explanatory variables
x1 = rnormal(n,1,0,1):*4	
x2 = rnormal(n,1,0,1):*4	 
x3 = rnormal(n,1,0,1):*4	
x4 = rnormal(n,1,0,1):*4
x5 = rnormal(n,1,0,1):*4


//generating error terms
epsreg 	= rnormal(n,1,0,1);
epseq1 	= rnormal(n,1,0,1);
epseq2 	= rnormal(n,1,0,1);

//this part for correlation
rho1 = 0.3
rho2 = 0.5

epseq1 = epseq1 * sqrt(1 - rho1^2) + epsreg * rho1
epseq2 = epseq2 * sqrt(1 - rho2^2) + epsreg * rho2

//This can be changed to specify overlap or not  
//note that we multiply the coefficients with the reqeq etc. to get the true coefficients
  
//complete overlap
//regeq = (1,0,0,0,0); 
//outeq1 = (0,1,1,0,0);
//outeq2 = (0,1,1,0,0); 

//no overlap
//regeq = (1,0,0,0,0); 
//outeq1 = (0,1,1,0,0);
//outeq2 = (0,0,0,1,1);

//partial overlap
regeq = (1,0,1,0,0); 
outeq1 = (0,1,1,0,0);
outeq2 = (0,0,1,1,0);

//overlap or not can be changed
mu      = (0.20);						//complete overlap
//mu      = (0.10);						//no overlap
//mu      = (0.12);						//partial overlap

//coefficients before multiplying
gamma = (2, 0, 1, 0, 0)
beta1    = (0, 2, 1, 0, 0)
beta2    = (0, 1, -2, 1, -2)

//a1     = (-3.83, 3.81);				//complete overlap
//a2     = (-3.83, 3.93);				//complete overlap	
a1     = (-5.23, 2.46);					//no overlap WRONG THIS IS PARTIAL
a2     = (-6.17, 0.97);					//no overlap
//a1     = (-3.85, 3.92);					//partial overlap
//a2     = (-3.81, 4.13);					//partial overlap	


// building model

gamma 	= gamma :* regeq			// select coefficients in the model
beta1 	= beta1 :* outeq1
beta2 	= beta2 :* outeq2

x 	= (x1, x2, x3, x4, x5); 

// check for multicollinearity among covariates
corrx	= correlation(x);
vnames	= strofreal(range(1, cols(x),1) * J(1,cols(x),1));	//column of strings 1, 2, ...
vnames	= "x" :+ vnames :+ ", x" :+ vnames';				// matrix
corrvec = abs(vech(corrx-I(cols(x)))):>0.1
if(sum(corrvec)>0){
	display ("CORRELATION IS greater than 0.1 BETWEEN FOLLOWING VARIABLES:");
	display(select(vech(vnames), corrvec));
}

rs 		= x * gamma' + epsreg;				// regime equation
r 		= J(n, 2, 0);

r[.,1]  = rs :< mu; 					//regime 1 decision
r[.,2]  = rs :>= mu;					//regime 2 decision
			
rvec	= rowsum(r*(-1,1)');				// -1 indicates reg1, 1 reg2

ys1     = x * beta1' + epseq1;				// second layer of y
ys2     = x * beta2' + epseq2;

y1                	= J(n, cols(a1)+1,0);
y1[., 1]           	= ys1 :< a1[1]; 		    //dummy if outc 1
y1[., 2]		= (ys1 :>= a1[1]) :* (ys1:< a1[2]); //dummy if outc 2	
y1[., cols(a1)+1]	= ys1 :>= a1[2];		    //dummy if outc 3


y2                	= J(n, cols(a2)+1,0);
y2[., 1]           	= ys2 :< a2[1]; 		    //dummy if outc 1
y2[., 2]		= (ys2 :>= a2[1]) :* (ys2:< a2[2]); //dummy if outc 2	
y2[., cols(a2)+1]	= ys2 :>= a2[2];		    //dummy if outc 3


y1      = y1*range(0,2,1); // specify outcomes
y2      = y2*range(0,2,1); // specify outcomes

yr      = (y1,y2);
y       = rowsum(r :* yr);	// observed y, depends on regime

ycat	= uniqrows(y);		// column 1 2 3

// here data must have been saved on disk, but I instead load it to the Stata dataset

end							// now switch from mata to stata!

getmata y=y x1=x1 x2=x2 x3=x3 x4=x4 x5=x5 r=rvec, replace force	// copy all variables to Stata interface
disp "	New variables y x1 x2 x3 x4 x5 r have been created"
disp "         Sample descriptive statistics"
sum y x1 x2 x3 x4 x5
disp "Frequency distribution of discrete categories of y"
tab y
disp "Frequency distribution of regimes"
tab r
disp "                 Decomposition of 0"
tab r if y==0
disp "                 Decomposition of 1"
tab r if y==1
disp "                 Decomposition of 2"
tab r if y==2
