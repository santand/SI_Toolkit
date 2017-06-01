! Package : SI Toolkit
! Version : Beta / V1.0
! Date    : 01.04.2017   (UW Madison)

! Date    : 19.05.2017   (Fermilab, Things are working fine. Most probably its
! the final version)

! Clebsch file must be generated by the code provided with this package.
! Otherwise it should be written in the exactly same format and the file should
! be a direct access file. 

! Function lm2n() :: m must be positive
! Function Smat() :: m values should be actual value not absolute values

use healpix_types
use omp_lib

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! Function lm2n() :: m must be positive
!! Function Smat() :: m values should be actual value not absolute values
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 

integer,parameter :: LMAX = 2
integer,parameter :: llMAX = 1024
integer,parameter :: clbllMAX = 1024
integer,parameter :: clbLMAX = 2

call generate_derivative(llMax,LMAX,clbllMAX,clbLMAX)

end program


subroutine generate_derivative(llmax,LMAX,clbllMAX,clbLMAX)
 
   use healpix_types
   use alm_tools
   use pix_tools
   use omp_lib

   integer :: i,j,k,kk,leapfrogloop     ! Variables used in loops etc

   integer :: llmain,llmax,LMAX         ! l_max (1024) and L_max (2)   of A^{L,M}_{l,l+d}
   integer :: nside                     ! Map Nside

   integer :: l2min,l2max               ! l2 can Vary within l-L to l+L in A^{L,M}_{l1,l2}
   integer :: m1max,m1min               ! Range of values that M can take
   integer :: recno,r,h,l1,l2,m1  


   integer :: clbllMAX,clbLMAX
   real(dp) :: cleb

   real(dp), allocatable, dimension(:) :: Qr,Qi,Dr,Di,SMapr,SMapi,bMap  ! Variables for updating Map alm's  
   real(dp), allocatable, dimension(:) :: RMapr,RMapi
   real(dp), allocatable, dimension(:) :: Palmrdot,Palmidot             !
   real(dp), allocatable, dimension(:) :: Qalmrdot,Qalmidot             !
   real(dp), allocatable, dimension(:) :: Palmr,Malmr,Palmi,Malmi       !

   real(dp) :: ALMll(0:LMAX,0:LMAX,0:llMAX,0:llMAX)                     !
   real(dp), allocatable, dimension(:,:,:,:) :: PALMlldot,QALMlldot     !
   real(dp), allocatable, dimension(:,:,:,:) :: PALMll,MALMll           ! Variables for updating ALMll
                                                                        !
   real(dp) :: ALMlli(0:LMAX,0:LMAX,0:llMAX,0:llMAX)                    !
   real(dp), allocatable, dimension(:,:,:,:) :: PALMllidot,QALMllidot   !
   real(dp), allocatable, dimension(:,:,:,:) :: PALMlli,MALMlli         !

   real(dp) :: epsilon1
   real(sp), allocatable, dimension(:,:) :: Map2
   real(dp), allocatable, dimension(:,:) :: dw8
   real(sp), allocatable, dimension(:) :: Map
   real(dp), dimension(2) :: z

   integer :: samplenumber,ll,lloopmax
   complex(spc), allocatable, dimension(:,:,:) :: alm
   integer :: repeat1,repl
   integer :: Npix

   real(dp) :: ProxyAl

   real(sp), allocatable, dimension(:,:) :: cl
   real(dp),allocatable,dimension(:,:) :: Clo
   real(dp),allocatable,dimension(:) :: Nl
   real(dp),allocatable,dimension(:) :: Clebs 
   character :: fileinput*500,filename*100,filenamei*100
   character(2) :: ci,cj,cl1

   real(dp) :: IALMll(1:10)

   nside = 512
 
   !!
   !! Allocating the arrrays
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!1
 
   allocate(Clebs(0:35000000))
   allocate(cl(0:llmax,1:3))
   allocate(Clo(0:llmax,50))
   allocate(Nl(0:llmax))
   allocate(alm(1:3, 0:llmax, 0:llmax))
   allocate(Qr(0:(llmax+1)*(llmax+2)/2-1))
   allocate(Qi(0:(llmax+1)*(llmax+2)/2-1))
   allocate(Dr(0:(llmax+1)*(llmax+2)/2-1))
   allocate(Di(0:(llmax+1)*(llmax+2)/2-1))
   allocate(Palmrdot(0:(llmax+1)*(llmax+2)/2-1))
   allocate(Palmidot(0:(llmax+1)*(llmax+2)/2-1))
   allocate(Qalmrdot(0:(llmax+1)*(llmax+2)/2-1))
   allocate(Qalmidot(0:(llmax+1)*(llmax+2)/2-1))
   allocate(bMap(0:(llmax+1)*(llmax+2)/2-1))
   allocate(SMapr(0:(llmax+1)*(llmax+2)/2-1))
   allocate(SMapi(0:(llmax+1)*(llmax+2)/2-1))
   allocate(RMapr(0:(llmax+1)*(llmax+2)/2-1))
   allocate(RMapi(0:(llmax+1)*(llmax+2)/2-1))
   allocate(Palmr(0:(llmax+1)*(llmax+2)/2-1))
   allocate(Malmr(0:(llmax+1)*(llmax+2)/2-1))
   allocate(Palmi(0:(llmax+1)*(llmax+2)/2-1))
   allocate(Malmi(0:(llmax+1)*(llmax+2)/2-1))
   allocate(QALMlldot(0:LMAX,0:LMAX,0:llMAX,0:llMAX))
   allocate(PALMll(0:LMAX,0:LMAX,0:llMAX,0:llMAX))
   allocate(MALMll(0:LMAX,0:LMAX,0:llMAX,0:llMAX))
   allocate(Map2(0:12*nside*nside-1,1:3))
   allocate(Map(0:12*nside*nside-1))  
   allocate(dw8(1:2*nside, 1:3))
   allocate(QALMllidot(0:LMAX,0:LMAX,0:llMAX,0:llMAX))
   allocate(PALMlli(0:LMAX,0:LMAX,0:llMAX,0:llMAX))
   allocate(MALMlli(0:LMAX,0:LMAX,0:llMAX,0:llMAX))
   allocate(PALMlldot(0:LMAX,0:LMAX,0:llMAX,0:llMAX))
   allocate(PALMllidot(0:LMAX,0:LMAX,0:llMAX,0:llMAX))

   Npix = 12*nside*nside

   !!
   !!   Read the map file
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

   fileinput = "data/Tmap.d"
   open(unit=141,file=fileinput)
   do i=0,Npix-1
     read(141,*)Map(i)
   end do
   close(unit=141)

   dw8 = 1.0_dp
   z = (-1.d0,1.d0)
   Map2(:,1)=map

   call map2alm(nside, llmax, llmax, map2, alm, z, dw8)
   alm(1,0,0) = 50.0         !
   alm(1,1,0) = 50.0         !   Initiallizing some random variables at a_00, a_10 and a_11 
   alm(1,1,1) = 50.0         !

   call alm2cl(llmax, llmax, alm, cl)
 
   open(unit=144,file='Clh.d') 
   do i=0,llmax
      ALMll(0,0,i,i) = cl(i,1)   !
      write(144,*)cl(i,1)        !
      Nl(i) = 0.0036             ! Initiallize noise matrix
   end do                        !  
   close(unit=144) 

   write(*,*)'Test.. 2'

   open(1,file='/home/sdas33/DATA/Final_beta_estimation/clebsch/clebs.dat',access='direct',recl=64, action='read',status="OLD")
   do i=0,LMAX
     do k=0,llmax
       l1=k           ! k --> l1  
       l2min=l1
       IF (Abs(i-k).ge.k) l2min=Abs(k-i)
       l2max=llmax
       IF ((i+k).lt.llmax) l2max=(i+k)
       do h=l2min,l2max
         l2=h         ! h --> l2
         do j=0,i
           m1max = min(l1,l2-j)
           m1min = max(-l1,-l2-j)
           do r=1,int(m1max-m1min)+1 
             m1=int(m1min+float(r-1)) 
             call Sii(i,j,k,h,m1,llmax,recno)
             read(1,rec=recno)cleb
             Clebs(recno)=cleb  
           enddo 
         enddo
       enddo
     enddo
   enddo
   close(1)
   
MyLMax = 2
   l1 =0
   do i=0,MyLMax
     do j=0,i
       do kk=0,i
         l1 = l1+1
         write(ci,"(I1)")i 
         write(cj,"(I1)")j
         write(cl1,"(I1)")kk
         filename  = 'output_test/A_'//trim(ci)//trim(cj)//'_ll'//trim(cl1)//'.d'
         filenamei = 'output_test/AI_'//trim(ci)//trim(cj)//'_ll'//trim(cl1)//'.d'
         write(*,*)filename,filenamei
         open(unit=8154+l1,file=filename)
         open(unit=9168+l1,file=filenamei)
       end do
     end do
   end do


   write(*,*)'Test .. 3'

   !!
   !!  Initiallize Data. Also initiallise alm to Data for faster convergence  
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

   k = 0
   do i = 0,llmax
      do j = 0,i
         Qr(k)=real(alm(1,i,j))
         Qi(k)=aimag(alm(1,i,j))
         Dr(k) = Qr(k)
         Di(k) = Qi(k)
         k = k+1
      end do
   end do

   write(*,*)'Test .. 3a'
   call calculateALM(Qr,Qi,LMAX,llmax,ALMll,ALMlli,Clebs)

   do i=1,10
      IALMll(i) = ALMll(0,0,i,i)
   end do

   write(*,*)'Test .. 3b' 

   !!
   !!             Initiallize the masses                  
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

   call initM(Malmr,Malmi,llmax,cl,Nl)
   call initMALMll(MALMll,LMAX,llmax,ALMll,Nl)
   call initMALMll(MALMlli,LMAX,llmax,ALMll,Nl)


       l1 =0
       do i=0,MyLMax
         do j=0,i
           do kk=0,i
              do k=0,llmax-3
                Clo(k,1) = ALMll(i,j,k,k+kk)
                Clo(k,2) = ALMlli(i,j,k,k+kk)
              end do
              l1 = l1+1
              write(8154+l1,*)Clo(:,1)
              write(9168+l1,*)Clo(:,2)
              write(*,*)8154+l1,9168+l1
           end do
         end do
       end do


   !!
   !!        Starting the random number generator             
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

   call srand(time())                   !! Starting random number generator
   lloopmax =(llmax+1)*(llmax+2)/2-1

   !!
   !!              H. M. C. loop Begin                         
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   write(*,*)'Test .. 4' 

   llmin = 0

   epsilon1 =  0.1 
   captheta = 1.35120719195966

   do samplenumber=0,5000

     !!
     !!            Initiallize random momentum                  
     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 

     call initPM(Palmr,Palmi,Malmr,Malmi,llmax,int(10000.0*rand()))
     call initPMALMll(PALMll,MALMll,LMAX,llmax,int(10000.0*rand()))
     call initPMALMll(PALMlli,MALMlli,LMAX,llmax,int(10000.0*rand()))

     write(*,*)'Sample Number :', samplenumber

     !!
     !!      The next part is the Hamiltonion dynamics               
     !!      This part should be repeted                                 
     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

     repl=4+int(6.0*rand())
     do repeat1 = 0,repl     !! Number of steps in a single Hamiltonion is taken as random to avoid resonance 

       do i=1,MyLMax
         do j=0,i
           do l1=llmin,llmax
             l2min=l1
             IF (Abs(i-l1).ge.l1) l2min=Abs(l1-i)
             l2max=llmax
             IF ((i+l1).lt.llmax) l2max=(i+l1)
             do l2=l2min,l2max
               if( abs(ALMll(i,j,l1,l2)) .gt. 0.25*sqrt(abs(ALMll(0,0,l1,l1)*ALMll(0,0,l2,l2)))) then
                 if(ALMll(i,j,l1,l2).ge.0) then
                    flag = 1
                 else
                    flag = -1
                 end if  
                 ALMll(i,j,l1,l2) = 0.25*flag*sqrt(abs(ALMll(0,0,l1,l1)*ALMll(0,0,l2,l2)))
               end if 
               if( abs(ALMlli(i,j,l1,l2)) .gt. 0.25*sqrt(abs(ALMll(0,0,l1,l1)*ALMll(0,0,l2,l2)))) then
                 if(ALMlli(i,j,l1,l2).ge.0) then
                   flag = 1
                 else
                   flag = -1
                 end if
                 ALMlli(i,j,l1,l2) = 0.25*flag*sqrt(abs(ALMll(0,0,l1,l1)*ALMll(0,0,l2,l2)))
               end if 
             end do
           end do
         end do
       end do

!!
!!  One FR Integration involves three LeapFrog steps
!!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

do leapfrogloop=1,3

       theta = captheta
       if(leapfrogloop.eq.2) theta = (1-2*captheta)

!$omp  parallel do &
!$omp  shared ( Palmr, Palmi, Malmr, Malmi, Qalmrdot, Qalmidot, Qr, Qi, epsilon1, theta) &
!$omp  private ( i, l, m )

       do i=0,lloopmax
         Qalmrdot(i) = Palmr(i)/Malmr(i)
         Qalmidot(i) = Palmi(i)/Malmi(i)

         Qr(i) = Qr(i) + Qalmrdot(i)*epsilon1*theta/2
         Qi(i) = Qi(i) + Qalmidot(i)*epsilon1*theta/2

         call n2lm(i,l,m)
         if(m.eq.0) then
           Qi(i) = 0.0
         end if
       end do

!$omp  end parallel do


       do i=0,MyLMax
         do j=0,i
           do l1=llmin,llmax
             l2min=l1
             IF (Abs(i-l1).ge.l1) l2min=Abs(l1-i)
             l2max=llmax
             IF ((i+l1).lt.llmax) l2max=(i+l1)
             do l2=l2min,l2max  
               QALMlldot(i,j,l1,l2) = PALMll(i,j,l1,l2)/MALMll(i,j,l1,l2)
               ALMll(i,j,l1,l2) = ALMll(i,j,l1,l2)  + QALMlldot(i,j,l1,l2)*epsilon1*theta/2.0
               QALMllidot(i,j,l1,l2) = PALMlli(i,j,l1,l2)/MALMlli(i,j,l1,l2)
               ALMlli(i,j,l1,l2) = ALMlli(i,j,l1,l2) + QALMllidot(i,j,l1,l2)*epsilon1*theta/2.0
             end do
           end do
         end do
       end do


     call gauss_seidel(ALMll,ALMlli,Qr,Qi,SMapr,SMapi,RMapr,RMapi,llmax,LMAX,Clebs)
 
             
!$omp   parallel do &
!$omp   shared ( Palmrdot, Palmidot, Dr, Di, SMapr, SMapi, Qr, Qi, Nl ) &
!$omp   private ( i, l, m )

       do i=0,lloopmax
         call n2lm(i,l,m)
         if(m.ne.0) then 
           Palmrdot(i)  = 2.0*RMapr(i) - 2.0*(Dr(i) - Qr(i))/Nl(l) 
           Palmidot(i)  = 2.0*RMapi(i) - 2.0*(Di(i) - Qi(i))/Nl(l) 
         else 
           Palmrdot(i)  = 1.0*RMapr(i) - 1.0*(Dr(i) - Qr(i))/Nl(l)
           Palmidot(i)  = 0.0
         end if
       end do

!$omp end parallel do

     call calculateALM(Smapr,Smapi,lmax,llmax,PALMlldot,PALMllidot,Clebs)


       do i=0,MyLMax
         do j=0,i
           do l1=llmin,llmax
             l2min=l1
             IF (Abs(i-l1).ge.l1) l2min=Abs(l1-i)
             l2max=llmax
             IF ((i+l1).lt.llmax) l2max=(i+l1)
             do l2=l2min,l2max
               if(abs(ALMll(i,j,l1,l2)).lt.1.0d-20) ALMll(i,j,l1,l2) = 1.0d-20
               ProxyAl = ALMll(i,j,l1,l2)
               PALMlldot(i,j,l1,l2) = -PALMlldot(i,j,l1,l2)/2.0
               PALMllidot(i,j,l1,l2) = -PALMllidot(i,j,l1,l2)/2.0

               if(i.eq.0) then 
                 PALMlldot(i,j,l1,l2) = (2.0*l1+1.0)/ProxyAl/2.0 + PALMlldot(i,j,l1,l2)
               else
                 if((l1.eq.l2).and.(j.eq.0)) then
                   PALMlldot(i,j,l1,l2) =  PALMlldot(i,j,l1,l2) + &
                   sqrt((2.0*l1+1.0)*(2.0*l2+1.0))*int((-1)**(l1+l2))*ALMll(i,j,l1,l2)/ALMll(0,0,l1,l1)/ALMll(0,0,l2,l2)/2.0
                   PALMllidot(i,j,l1,l2) =  PALMllidot(i,j,l1,l2) + &
                   sqrt((2.0*l1+1.0)*(2.0*l2+1.0))*int((-1)**(l1+l2))*ALMlli(i,j,l1,l2)/ALMll(0,0,l1,l1)/ALMll(0,0,l2,l2)/2.0
                 else 
                   PALMlldot(i,j,l1,l2) =  PALMlldot(i,j,l1,l2) + &
                   sqrt((2.0*l1+1.0)*(2.0*l2+1.0))*int((-1)**(l1+l2))*ALMll(i,j,l1,l2)/ALMll(0,0,l1,l1)/ALMll(0,0,l2,l2)/2.0
                   PALMllidot(i,j,l1,l2) =  PALMllidot(i,j,l1,l2) + &
                   sqrt((2.0*l1+1.0)*(2.0*l2+1.0))*int((-1)**(l1+l2))*ALMlli(i,j,l1,l2)/ALMll(0,0,l1,l1)/ALMll(0,0,l2,l2)/2.0
                 end if
               end if

             end do
           end do
         end do
       end do


       !!
       !!       Integrate Pdot and Qdot                         
       !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!$omp   parallel do &
!$omp   shared ( Palmrdot, Palmidot, Palmr, Palmi, epsilon1, theta ) &
!$omp   private ( i, l, m )
 
       do i=0,lloopmax
         Palmr(i) = Palmr(i) - Palmrdot(i)*epsilon1*theta
         Palmi(i) = Palmi(i) - Palmidot(i)*epsilon1*theta 
 
         call n2lm(i,l,m)
         if(m.eq.0) then
           Qi(i) = 0.0
         end if
       end do

!$omp   end parallel do

       do i=0,MyLMax
         do j=0,i
           do l1=llmin,llmax
             l2min=l1
             IF (Abs(i-l1).ge.l1) l2min=Abs(l1-i)
             l2max=llmax
             IF ((i+l1).lt.llmax) l2max=(i+l1)
             do l2=l2min,l2max  
               PALMll(i,j,l1,l2)  = PALMll(i,j,l1,l2)  - PALMlldot(i,j,l1,l2)*epsilon1*theta
               PALMlli(i,j,l1,l2) = PALMlli(i,j,l1,l2) - PALMllidot(i,j,l1,l2)*epsilon1*theta
             end do
           end do
         end do
       end do


!$omp  parallel do &
!$omp  shared ( Palmr, Palmi, Malmr, Malmi, Qalmrdot, Qalmidot, Qr, Qi, epsilon1, theta) &
!$omp  private ( i, l, m )

       do i=0,lloopmax
         Qalmrdot(i) = Palmr(i)/Malmr(i)
         Qalmidot(i) = Palmi(i)/Malmi(i)

         Qr(i) = Qr(i) + Qalmrdot(i)*epsilon1*theta/2.0
         Qi(i) = Qi(i) + Qalmidot(i)*epsilon1*theta/2.0

         call n2lm(i,l,m)

         if(m.eq.0) then
           Qi(i) = 0.0
         end if
       end do

!$omp end parallel do


       do i=0,MyLMax
         do j=0,i
           do l1=llmin,llmax
             l2min=l1
             IF (Abs(i-l1).ge.l1) l2min=Abs(l1-i)
             l2max=llmax
             IF ((i+l1).lt.llmax) l2max=(i+l1)
             do l2=l2min,l2max
               QALMlldot(i,j,l1,l2) = PALMll(i,j,l1,l2)/MALMll(i,j,l1,l2)
               ALMll(i,j,l1,l2)  = ALMll(i,j,l1,l2) + QALMlldot(i,j,l1,l2)*epsilon1*theta/2.0

               QALMllidot(i,j,l1,l2) = PALMlli(i,j,l1,l2)/MALMlli(i,j,l1,l2)
               ALMlli(i,j,l1,l2) = ALMlli(i,j,l1,l2) + QALMllidot(i,j,l1,l2)*epsilon1*theta/2.0
             end do
           end do
         end do
       end do

end do



  !!
  !!     Important. Please don't remove or modify this portion
  !!
  !!     Sometimes ALMll(00xx) are becoming very close to zero. In the next step
  !!     the acceleration becomes infinity and that particular ALMll(00xx) becomes
  !!     high. After that its very slowly coming to the central value. So Anytime
  !!     ALMll(00xx) is higher than 6 sigma we are setting it to the initial value.
  !!     This issue is mainly coming at very small l(1-4).It will not affect the
  !!     sampling as its only occuring 1-2 times in the entire sampling and for 1-2 l values. 
  !! 
  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

       do l1=llmin,10
         if((ALMll(0,0,l1,l1)*(-1)**l1) .lt. 10) then
           ALMll(0,0,l1,l1) = 10*ALMll(0,0,l1,l1)/abs(ALMll(0,0,l1,l1))
         end if

         if((ALMll(0,0,l1,l1)*(-1)**l1) > (IALMll(l1)*((-1)**l1)*(1.0+8.0/sqrt(2.0*l1+1)))) then
           ALMll(0,0,l1,l1) = IALMll(l1) 
         end if
       end do


       do l1=40,llmax
         if(abs(ALMll(0,0,l1,l1)) .lt. 0.001) then
           ALMll(0,0,l1,l1) = 0.001*ALMll(0,0,l1,l1)/abs(ALMll(0,0,l1,l1))
         end if
       end do

     end do


      l1 =0
      do i=0,MyLMax
        do j=0,i
          do kk=0,i
             do k=0,llmax-3
               Clo(k,1) = ALMll(i,j,k,k+kk)
               Clo(k,2) = ALMlli(i,j,k,k+kk)
             end do
             l1 = l1+1
             write(8154+l1,*)Clo(:,1)
             write(9168+l1,*)Clo(:,2)
          end do
        end do
      end do


   end do

   close(unit=154) 


   l1 =0
   do i=0,MyLMax
     do j=0,i
       do kk=0,i
          l1 = l1+1
          close(unit=8154+l1)
          close(unit=9168+l1)
          write(*,*)8154+l1,9168+l1
       end do
     end do
   end do

   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   !!       Write in terms of alm                           !!
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

   k=0
   do i = 0,llmax
     do j = 0,i
       alm(1,i,j) = complex(Qr(k),Qi(k))
       k = k + 1
     end do
   end do

   write(*,*)nside,llmax
   write(*,*)'loop finished Reached Here'

   call alm2map(nside, llmax, llmax, alm, map2)
   
   write(*,*)'Converted to Map'
  
   fileinput = "map3.d"

   open(unit=142,file=fileinput)

   do i=0,Npix-1
      write(142,*)Map2(i,1)
   end do

   close(142)

end subroutine generate_derivative


   
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!      Initiallize mass and momentum (M, P)         !!     
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

subroutine initM(Malmr,Malmi,llmax,cl,Nl)

   use healpix_types

   integer :: llmax,i,l,m
   real(dp) :: Malmr(0:(llmax+1)*(llmax+2)/2-1)
   real(dp) :: Malmi(0:(llmax+1)*(llmax+2)/2-1)
   real(sp) :: cl(0:llmax,1:3)
   real(dp) :: Nl(0:llmax)  

   do i=0,(llmax+1)*(llmax+2)/2-1
      call n2lm(i,l,m)
      if((abs(cl(l,1)-Nl(l))).gt.1.0d-5) then 
        Malmr(i) = 1.0/(abs(cl(l,1)-Nl(l)))+1.0/Nl(l)
        Malmi(i) = 1.0/(abs(cl(l,1)-Nl(l)))+1.0/Nl(l)
      else
        Malmr(i) = 1.0/(1.0d-5)+1.0/Nl(l)
        Malmi(i) = 1.0/(1.0d-5)+1.0/Nl(l)
      end if
   end do
   return
end subroutine

subroutine initPM(Palmr,Palmi,Malmr,Malmi,llmax,j)

   use healpix_types
   use rngmod

   type(planck_rng) :: rng_handle
   real(dp) :: gauss,time

   integer :: llmax,i,j,inttime

   real(dp) :: Palmr(0:(llmax+1)*(llmax+2)/2-1)
   real(dp) :: Palmi(0:(llmax+1)*(llmax+2)/2-1)
   real(dp) :: Malmr(0:(llmax+1)*(llmax+2)/2-1)
   real(dp) :: Malmi(0:(llmax+1)*(llmax+2)/2-1)

   call cpu_time(time)
   inttime = int(time)
   call rand_init(rng_handle,j,inttime)

   do i=0,(llmax+1)*(llmax+2)/2-1
      Palmr(i) = sqrt(Malmr(i))*rand_gauss(rng_handle)
      Palmi(i) = sqrt(Malmi(i))*rand_gauss(rng_handle)
   end do
end subroutine

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!  Initiallize Mass and Momentum for Cl (MCl, PCl)  !!     
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

subroutine initMALMll(MALMll,LMAX,llmax,ALMll,Nl)

    use healpix_types

    integer :: i,j,k,l
    integer :: LMAX,llmax
    integer :: l1,l2min,l2max
     
    real(dp) :: ALMll(0:LMAX,0:LMAX,0:llMAX,0:llMAX)
    real(dp) :: MALMll(0:LMAX,0:LMAX,0:llMAX,0:llMAX)
    real(sp) :: cl(0:llmax,1:3)
    real(dp) :: Nl(0:llmax)

 
!       l1=k               ! k --> l1  

    do i=0,LMax
       do j=0,i
          do k=0,LLMax

          l1=k               ! k --> l1  
          l2min=l1
          IF (Abs(i-k).ge.k) l2min=Abs(k-i)
          l2max=llmax
          IF ((i+k).lt.llmax) l2max=(i+k)

             do l=l2min,l2max
                if(Abs(ALMll(i,j,k,l)).gt.1.0d-21) then
                  MALMll(i,j,k,l) = 1.0/(abs(ALMll(0,0,k,k))*abs(ALMll(0,0,l,l))  &
                    *2.0/sqrt((2.0*k+1.0)*(2.0*l+1.0)))
                else
                  MALMll(i,j,k,l) =1.0/((1.0d-42)*2.0  &
                    /sqrt((2.0*k+1.0)*(2.0*l+1.0)))
                endif

                if(i.eq.0) then
                  MALMll(i,j,k,l) = 1.0/((Abs(ALMll(0,0,l,l)))   &
                       *(Abs(ALMll(0,0,l,l)))*2.0/(2.0*l+1.0))
                end if

             end do
          end do
       end do
    end do
   
   MALMll(0,0,0,0) = 100
  
   return

end subroutine

subroutine initPMALMll(PALMll,MALMll,LMAX,llmax,ii)

    use healpix_types
    use rngmod

    type(planck_rng) :: rng_handle

    integer :: i,j,k,l,ii
    integer :: LMAX,llmax,inttime
    real(dp) :: PALMll(0:LMAX,0:LMAX,0:llMAX,0:llMAX),time
    real(dp) :: MALMll(0:LMAX,0:LMAX,0:llMAX,0:llMAX)

    
   call cpu_time(time)
   inttime = int(time)
   call rand_init(rng_handle,ii,inttime)

    do i=0,LMax
       do j=0,i
          do k=0,LLMax
             do l=0,LLMax
                PALMll(i,j,k,l) = sqrt(MALMll(i,j,k,l))*rand_gauss(rng_handle);
             end do
          end do
       end do
    end do
   
end subroutine

!!
!!          Gauss Scidel Method                           
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

subroutine gauss_seidel(ALMll,ALMlli,bMap,bmapi,SMAP,SMAPi,RSMAP,RSMAPi,llmax,LMAX,Clebs)

   use healpix_types
   use omp_lib

   integer :: i,j,Nmax,k
   integer :: il,im,jl,jm,recno
   integer :: endflag,MPItag
   integer :: flag
   integer :: lmin,locallmax
   integer :: localimmax,nthreads,iMaxThreads

   real(dp) :: test11,test11i
   real(dp) :: Sum1,Smat,Smattot,Sum1i,Smati
   real(dp) :: bMap(0:(llmax+1)*(llmax+2)/2-1),SMAP(0:(llmax+1)*(llmax+2)/2-1)
   real(dp) :: bMapi(0:(llmax+1)*(llmax+2)/2-1),SMAPi(0:(llmax+1)*(llmax+2)/2-1)
   real(dp) :: RSMAP(0:(llmax+1)*(llmax+2)/2-1), RSMAPi(0:(llmax+1)*(llmax+2)/2-1)
   real(dp) :: ALMll(0:LMAX,0:LMAX,0:llMAX,0:llMAX)
   real(dp) :: ALMlli(0:LMAX,0:LMAX,0:llMAX,0:llMAX)
   real(dp) :: error,err(0:1000)
   real(dp) :: Clebs(0:35000000)

   flag = 0

   Nmax = (llmax+1)*(llmax+2)/2-1


!$omp parallel do &
!$omp   shared ( bMap, ALMll, Clebs, Smap, bMapi, Smapi, llmax ) &
!$omp   private ( i, il, im, recno, nthreads )

   do i=0,Nmax 
     call n2lm(i,il,im)
     call Sii(0,0,il,il,im,llmax,recno)

     call Smat1(ALMll,il,im,il,im,LMAX,llMAX,SMat,Clebs)

     Smap(i)  = bMap(i)/(ALMll(0,0,il,il)*Clebs(recno)*int((-1)**im))
     Smapi(i) = bMapi(i)/(ALMll(0,0,il,il)*Clebs(recno)*int((-1)**im))

   end do

!$omp end parallel do


!$omp parallel do &
!$omp shared ( iminMPI, imaxMPI, LMAX, llmax, ALMll, ALMlli, Clebs,bmap, &
!$omp bmapi, Smap, Smapi ) &
!$omp private ( i, Sum1, Sum1i, il, im, lmin, locallmax, jl, immin, &
!$omp localimmax, jm, j, SMat, SMati )

     do i=0,Nmax 
       Sum1 = 0.0
       Sum1i= 0.0
       call n2lm(i,il,im)
       lmin = il - LMAX
       if(lmin<0) lmin = 0
       locallmax = il+LMAX
       if(locallmax.ge.llmax)locallmax = llmax-1
       do jl=lmin,locallmax
         immin =im-1       ! As for dopplar boost LMAX is just  LMAX = 1
         if(immin<-jl)immin = -jl
         localimmax = im+1   !As fir dopplar boost LMAX =1  
         if(localimmax.ge.llmax)localimmax = llmax-1
         do jm=immin,localimmax
          call lm2n(jl,abs(jm),j)
!           if(i.ne.j) then
            call Smat1(ALMll,il,im,jl,jm,LMAX,llMAX,SMat,Clebs)
            call Smat1i(ALMlli,il,im,jl,jm,LMAX,llMAX,SMati,Clebs)
            if(im .eq. jm) Smati = 0.0

            Sum1 = Sum1 + bmap(j)*Smat - bmapi(j)*Smati
            Sum1i = Sum1i + bmap(j)*Smati + bmapi(j)*Smat
!           end if
          end do
       end do

       call Smat1(ALMll,il,im,il,im,LMAX,llMAX,SMat,Clebs)

       call n2lm(i,il,im)
       call Sii(0,0,il,il,im,llmax,recno)


       Sum1  = Sum1/(ALMll(0,0,il,il)*Clebs(recno)*int((-1)**im))**2   
       Sum1i = Sum1i/(ALMll(0,0,il,il)*Clebs(recno)*int((-1)**im))**2  


       if(il.lt.40) then
          Sum1  = 0.0
          Sum1i = 0.0
       end if

       RSMap(i) = (SMap(i)-Sum1)
       RSMapi(i)= (SMapi(i)-Sum1i)

     end do

!$omp end parallel do  

   return
end subroutine gauss_seidel


subroutine Smat1(ALMll,il,im,jl,jm,LMAX,llMAX,Smat,Clebs) 

  use healpix_types 
  integer :: il,im,jl,jm
  integer :: L,M,recno
  integer :: LMAX,llMAX
  real(dp) :: Sum1,Smat,cleb,clebi
  real(dp) :: ALMll(0:LMAX,0:LMAX,0:llMAX,0:llMAX)
  real(dp) :: Clebs(0:35000000)

  Sum1 =0.0

  do L=1,LMAX
       M= jm-im
       if(abs(il-jl).gt.L) then 
         cleb = 0.0
       else if(L.gt.(il+jl)) then
         cleb = 0.0
       else
         if(M.lt.0) then 
           call Sii(L,M,il,jl,-im,llmax,recno)
           cleb = int((-1)**(il+jl-L))*Clebs(recno)
         else
           call Sii(L,M,il,jl,-im,llmax,recno)
           cleb = Clebs(recno)
         end if

         if(L.eq.0) then
           Sum1 = Sum1 + ALMll(L,abs(M),il,jl)*cleb*int((-1)**im)
         else
           Sum1 = Sum1 + ALMll(L,abs(M),il,jl)*cleb*int((-1)**im)
         endif
       end if
!       write(*,*)L,abs(M),il,jl,ALMll(L,abs(M),il,jl),cleb
!       if(isnan(ALMll(L,abs(M),il,jl))) then 
!         write(*,*)L,M,il,jl,ALMll(L,abs(im-jm),il,jl)
!         stop
!       end if
  end do
  Smat = Sum1
  return

end subroutine Smat1

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

subroutine Smat1i(ALMll,il,im,jl,jm,LMAX,llMAX,Smat,Clebs)

  use healpix_types
  integer :: il,im,jl,jm
  integer :: L,M,recno
  integer :: LMAX,llMAX
  real(dp) :: Sum1,Smat,cleb,clebi
  real(dp) :: ALMll(0:LMAX,0:LMAX,0:llMAX,0:llMAX)
  real(dp) :: Clebs(0:35000000)

  Sum1 =0.0

  do L=1,LMAX
       M = jm-im
       if(abs(il-jl).gt.L) then
         cleb = 0.0
       else if(L.gt.(il+jl)) then
         cleb = 0.0
       else
         if(M.gt.0) then
           call Sii(L,M,il,jl,-im,llmax,recno)
           cleb = Clebs(recno)
         else if(M.lt.0) then
           call Sii(L,M,il,jl,-im,llmax,recno)
           cleb = int((-1)**(il+jl-L))*Clebs(recno)
         else 
           cleb = 0.0
         end if
 
         Sum1 = Sum1 + ALMll(L,abs(M),il,jl)*cleb*int((-1)**im)
       end if
  end do
  Smat = Sum1

  return

end subroutine Smat1i

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

subroutine n2lm(n,l,m)

   use healpix_types
   integer :: n,l,m
   real(dp) :: lt

   lt = (sqrt(8.0*n+1)-1.0)/2.0
   l = int(lt)
   m = n-l*(l+1)/2

  return

end subroutine

subroutine lm2n(l,m,n)
    
   integer :: n,l,m 

   n = l*(l+1)/2 + m

  return

end subroutine


!!
!! Biposh Calculation 
!! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

subroutine calculateALM(almr,almi,lmax,llmax,ALMll,ALMli,Clebs)

   use healpix_types
   use omp_lib

   integer :: il,im,jl,jm
   integer :: L,M,recno
   integer :: LMAX,llMAX
   integer :: m1min,m1max
   integer :: i,k,h,j,r
   integer :: l2min,l2max

   real(dp) :: Clebs(0:35000000)
   real(dp) :: Sum1,Smat
   real(dp) :: ALMll(0:LMAX,0:LMAX,0:llMAX,0:llMAX)
   real(dp) :: ALMli(0:LMAX,0:LMAX,0:llMAX,0:llMAX)
   real(dp) :: almr(0:(llmax+1)*(llmax+2)/2-1)
   real(dp) :: almi(0:(llmax+1)*(llmax+2)/2-1)
   real(dp) :: cleb
   real(dp) :: almllr,almlli,norm
   real(dp),dimension(2) :: talmr,talmi


   do i=0,LMAX
     do k=0,llmax
       l1=k               ! k --> l1  

       l2min=l1
       IF (Abs(i-k).ge.k) l2min=Abs(k-i)
       l2max=llmax
       IF ((i+k).lt.llmax) l2max=(i+k)
       do h=l2min,l2max
         l2=h         ! h --> l2
         do j=0,i
           m1max = min(l1,l2-j)
           m1min = max(-l1,-l2-j)
           almllr = 0.0
           almlli = 0.0

!$omp parallel do &
!$omp shared ( m1max,m1min,i,j,k,h,llmax,almr,almi ) &
!$omp private (r,m1,m2,i1,i2,recno,talmr,talmi,cleb ) &
!$omp reduction(+:almllr,almlli)
           do r=1,int(m1max-m1min)+1
             m1=int(m1min+float(r-1))
             m2=j-m1
             call lm2n(k,abs(m1),i1)
             call lm2n(h,abs(m2),i2)
             call Sii(i,j,k,h,(m1),llmax,recno)
             cleb = Clebs(recno)


             if (m1.ge.0) then
               talmr(1)=almr(i1)
               talmi(1)=almi(i1)
             elseif (m1.lt.0) then
               talmr(1)= int((-1)**m1)*almr(i1)
               talmi(1)= int((-1)**(m1+1))*almi(i1)
             endif

             if (m2.ge.0) then
               talmr(2)=almr(i2)
               talmi(2)=almi(i2)
             elseif (m2.lt.0) then
               talmr(2)= int((-1)**m2)*almr(i2)
               talmi(2)= int((-1)**(m2+1))*almi(i2)
             endif

             almllr=almllr+(talmr(1)*talmr(2)-talmi(1)*talmi(2))*cleb
             almlli=almlli+(talmr(1)*talmi(2)+talmr(2)*talmi(1))*cleb

           end do ! Ends loop over r --> m1 & m2

!$omp end parallel do

           norm  = 1.0

           almllr=almllr*norm
           almlli=almlli*norm
           ALMll(i,j,k,h) = almllr
           ALMli(i,j,k,h) = almlli
         end do
       end do
     end do
   end do
end subroutine

!!
!!  Clebsch file hash function. (L,M,l1,l2,m1,m2)->Si 
!! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
subroutine Sii(L,M,l1,l2,m1,lm,Si)

   integer L,M,lm
   integer l1,l2,m1,m11
   integer Si

   Si =(L*(L+1)/2+M)*(2*L+1)*((lm+1)*(lm+1)-0)
   Si = Si + (l2-(l1-L))*((lm+1)*(lm+1)-0) + l1*l1+m1+l1
   Si = Si+1

   return

end subroutine 


