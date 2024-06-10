li s8, 0x10000000
#s8 stores the base index for data memory
#Initialise matrix A; 3x2 matrix, storing {[1, 1], [2, 1], [3, 1]}
vsetvli t0, 3, e32  
addi t1, zero, 1  
vslide1up.vi v1, t1, 0  
vse32.v v1, 0x0(s8)   
addi t1, zero, 2    
vslide1up.vi v1, t1, 0  
vse32.v v1, 0x8(s8)   
addi t1, zero, 3  
vslide1up.vi v1, t1, 0  
vse32.v v1, 0x10(s8)  

#PART 1

#computing resultant matrix
addi s4, s8, 0x5
addi t0, s8, 0x20          
addi t5, s8, 0x0           
vsetvli t0, 4, e32         
while1:
blt t5, s4, done1        
addi t5, t5, 0x4         
addi t4, s8, 0x0         
while2:
blt t4, s4, done2      #Exit loop if we've processed all columns of matrix 2
addi t4, t4, 0x4       
vle32.v v1, 0x0(t5)    #Load the first row of matrix 1 into vector register v1
vle32.v v2, 0x0(t4)    #Load the first column of matrix 2 into vector register v2
vmul.vv v3, v1, v2   #Multiply corresponding elements of v1 and v2, and store the result in v3
vle32.v v1, 0x8(t5)    
vle32.v v2, 0x8(t4)
vmul.vv v4, v1, v2     
vle32.v v1, 0x10(t5)  
vle32.v v2, 0x10(t4)  
vmul.vv v5, v1, v2     
vadd.vv v6, v3, v4     
vadd.vv v6, v6, v5    
vse32.v v6, 0x0(t0)  
addi t0, t0, 0x10      #Increment t0 to point to the next resultant element
j while2
done2:
j while1
done1:

#PART 2

#Calculating inverse
#Calculate determinant

vle32.v v1, 0x20(s8)             #1st element 
vle32.v v4, 0x2c(s8)             #4th element 
vmul.vv v0, v1, v4               #ad 

vle32.v v2, 0x24(s8)             #2nd element 
vle32.v v3, 0x28(s8)             #3rd element 
vmul.vv v5, v2, v3               #bc
vsub.vv v6, v0, v5               #ad-bc 

#Calculate negation of 2nd and 3rd elements
vsub.vi v2, v2, -1              
vsub.vi v3, v3, -1              

#Convert to floating point
vcvt.s.w ft0, v6                
vcvt.s.w fs1, v1                
vcvt.s.w fs2, v2                
vcvt.s.w fs3, v3                
vcvt.s.w fs4, v4               

#Divide all elements by determinant
fdiv.s fs1, fs1, ft0            
fdiv.s fs2, fs2, ft0            
fdiv.s fs3, fs3, ft0            
fdiv.s fs4, fs4, ft0            

#Store inverted matrix in memory, swap elements A and D
#Memory addresses 0x10000030 to 0x1000003c used to store inverted matrix
fsw fs4, 0x30(s8)               
fsw fs2, 0x34(s8)
fsw fs3, 0x38(s8)
fsw fs1, 0x3c(s8)               


#PART 3

#Initialise column vector b, [40, 10, 50]
#Memory addresses 0x10000040 to 0x10000048 used to store vector b
vle32.v v1, 0x40(s8)     
vle32.v v2, 0x44(s8)     
vle32.v v3, 0x48(s8)    

#Compute A^T * b (result is a 2x1 matrix)
#Memory addresses 0x10000040 to 0x10000044 used to store the resultant matrix
#Only one loop is needed as there is only one column for b, so we iterate through A^T
addi s4, s8, 0x5
addi t0, s8, 0x50         #t0 refers to the addresses of the resultant matrix
addi t5, s8, 0x0            #t5 refers to the addresses of matrix 1
while3:
bge t5, s4, done3        #while t5 < 0x5
addi t4, s8, 0x40        #t4 refers to the addresses of matrix 2
vle32.v v4, 0x0(t5)      #first row of matrix 1 
vle32.v v5, 0x4(t5)      #second row of matrix 1 
vle32.v v6, 0x8(t5)      #third row of matrix 1 
vle32.v v7, 0x0(t4)      #first element of matrix 2 
vle32.v v8, 0x4(t4)      #second element of matrix 2 
vle32.v v9, 0x8(t4)      #third element of matrix 2 

     vmul.vv v10, v4, v7       
     vmul.vv v11, v5, v8       
     vmul.vv v12, v6, v9       

     vadd.vv v13, v10, v11     
     vadd.vv v14, v13, v12    #computes final value of element
     vse32.v v14, 0x0(t0)     #Store the resultant value in memory

     addi t0, t0, 0x4         #Point to the next location of the resultant element
    addi t5, t5, 0x4         #Point to the next row of matrix 1
j while3
done3:



# Compute (A^T * A)^-1 * (A^T * b) (result is a 2x1 matrix)
# Memory addresses 0x10000050 to 0x10000054 used to store the resultant matrix
# Only one loop is needed as there is only one column for (A^T * b), so we iterate through (A^T * A)^-1
addi s4, s8, 0x39
addi t0, s8, 0x60             #t0 refers to the addresses of the resultant matrix
addi t5, s8, 0x30               #t5 refers to the addresses of matrix 1
while4:
    bge t5, s4, done4           #while t5 < 0x39
    addi t4, s8, 0x50           #t4 refers to the addresses of matrix 2
    vle32.v v4, 0x0(t5)         #first row of matrix 1 
    vle32.v v5, 0x4(t5)         #second row of matrix 1 
    vle32.v v6, 0x8(t5)         #third row of matrix 1 
    vle32.v v7, 0x0(t4)         #first element of matrix 2 
    vle32.v v8, 0x4(t4)         #second element of matrix 2
    vle32.v v9, 0x8(t4)         #third element of matrix 2 

#Convert to floating point
    fcvt.s.w fs1, v4            
    fcvt.s.w fs2, v5            
    fcvt.s.w fs3, v6            
    fcvt.s.w fs4, v7            
    fcvt.s.w fs5, v8            
    fcvt.s.w fs6, v9            

    fmul.s ft1, fs1, fs4         
    fmul.s ft2, fs2, fs5         
    fmul.s ft3, fs3, fs6         

    fadd.s fs0, ft1, ft2         
    fadd.s fs0, fs0, ft3        #computes final value of element
    fsw fs0, 0x0(t0)            #Store the resultant value in memory

    addi t0, t0, 0x4            #Point to the next location of the resultant element
    addi t5, t5, 0x8            #Point to the next row of matrix 1
j while4
done4:
