! Package : SI Toolkit
! Version : Beta / V1.0
! Date    : 01.04.2017   (UW Madison)
! Code    : Anisotropic Noise (no masking)

! Date    : 19.05.2017   (Fermilab, Things are working fine. Most probably its
! the final version)

! Clebsch file must be generated by the code provided with this package.
! Otherwise it should be written in the exactly same format and the file should
! be a direct access file. 

! Function lm2n() :: m must be positive
! Function Smat() :: m values should be actual value not absolute values


subroutine anisotropic(llmax,LMAX,clbllMAX,clbLMAX,nside,samplenumber,noisevariance,fileinput, &
noisefileinput,clebschpath,maskpath,chainpath,maskparam,isoparam)
 
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

   integer :: maskparam,isoparam

   integer :: clbllMAX,clbLMAX
   integer :: samplenumber
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
   real(sp), allocatable, dimension(:) :: NoiseMap
   real(sp), allocatable, dimension(:) :: MaskMap
   real(dp), dimension(2) :: z

   integer :: ll,lloopmax
   complex(spc), allocatable, dimension(:,:,:) :: alm, dfalm
   integer :: repeat1,repl
   integer :: Npix

   real(dp) :: ProxyAl

   real(sp), allocatable, dimension(:,:) :: cl
   real(dp),allocatable,dimension(:,:) :: Clo
   real(dp),allocatable,dimension(:) :: Nl
   real(dp),allocatable,dimension(:) :: Clebs 
   character :: fileinput*500,filename*100,filenamei*100,noisefileinput*100
   character :: clebschpath*500,maskpath*500
   character :: chainpath*500
   character(2) :: ci,cj,cl1

   real(dp) :: noisevariance
   real(dp) :: IALMll(1:10),timestart,timeend,noipix
   real(DP), dimension(:,:), allocatable :: plm 
   real(dp), allocatable, dimension(:) :: dfQr,dfQi

   !!
   !! Allocating the arrrays
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!1
 
   allocate(Clebs(0:35000000))
   allocate(cl(0:llmax,1:3))
   allocate(Clo(0:llmax,50))
   allocate(Nl(0:llmax))
   allocate(alm(1:3, 0:llmax, 0:llmax))
   allocate(dfalm(1:3, 0:llmax, 0:llmax))
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
   allocate(NoiseMap(0:12*nside*nside-1))
   allocate(MaskMap(0:12*nside*nside-1))
   allocate(dw8(1:2*nside, 1:3))
   allocate(QALMllidot(0:LMAX,0:LMAX,0:llMAX,0:llMAX))
   allocate(PALMlli(0:LMAX,0:LMAX,0:llMAX,0:llMAX))
   allocate(MALMlli(0:LMAX,0:LMAX,0:llMAX,0:llMAX))
   allocate(PALMlldot(0:LMAX,0:LMAX,0:llMAX,0:llMAX))
   allocate(PALMllidot(0:LMAX,0:LMAX,0:llMAX,0:llMAX))
   allocate(dfQr(0:(llmax+1)*(llmax+2)/2-1))
   allocate(dfQi(0:(llmax+1)*(llmax+2)/2-1))


   Npix = 12*nside*nside

   !!
   !!   Read the map file
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


   open(unit=141,file=fileinput)
   do i=0,Npix-1
     read(141,*)Map(i)
   end do
   close(unit=141)

   if(isoparam .eq. 1) then
   open(unit=144,file=noisefileinput)
   do i=0,Npix-1
     read(144,*)NoiseMap(i)
   end do
   close(unit=144)
   else
      do i=0,Npix-1
      NoiseMap(i) = noisevariance 
   end do
   end if

   if(maskparam .eq. 1) then 

   open(unit=146,file=maskpath)
   do i=0,Npix-1
     read(146,*)MaskMap(i)
   end do
   close(146)

   do i=0,Npix-1
     NoiseMap(i) = NoiseMap(i) + 99999.9*(1.0-MaskMap(i))
   end do

   end if

   dw8 = 1.0_dp
   z = (-1.d0,1.d0)
   Map2(:,1)=map

   call map2alm(nside, llmax, llmax, map2, alm, z, dw8)
   alm(1,0,0) = 50.0         !
   alm(1,1,0) = 50.0         !   Initiallizing some random variables at a_00, a_10 and a_11 
   alm(1,1,1) = 50.0         !

   call alm2cl(llmax, llmax, alm, cl)
 
!   open(unit=144,file='Clh.d') 
   do i=0,llmax
      ALMll(0,0,i,i) = cl(i,1)   !
!      write(144,*)cl(i,1)        !
      Nl(i) = 0.0036             ! Initiallize noise matrix
   end do                        !  
!   close(unit=144) 

   write(*,*)'Test.. 2'

   open(1,file=clebschpath,access='direct',recl=64, action='read',status="OLD")
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
   
   MyLMax = LMAX 

   l1 =0
   do i=0,MyLMax
     do j=0,i
       do kk=0,i
         l1 = l1+1
         write(ci,"(I1)")i 
         write(cj,"(I1)")j
         write(cl1,"(I1)")kk
         filename  = trim(chainpath)//'/AR_'//trim(ci)//trim(cj)//'_ll'//trim(cl1)//'.d'
         filenamei = trim(chainpath)//'/AI_'//trim(ci)//trim(cj)//'_ll'//trim(cl1)//'.d'
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

   call calculateALM(Qr,Qi,LMAX,llmax,ALMll,ALMlli,Clebs)

   do i=1,10
      IALMll(i) = ALMll(0,0,i,i)
   end do

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

   llmin = 0

   epsilon1 =  0.1 
   captheta = 1.35120719195966

   noipix = 0.000004*900 


   do samplenumber=0,samplenumber 

     call cpu_time(timestart)

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
     do repeat1 = 0, 7 !repl     !! Number of steps in a single Hamiltonion is taken as random to avoid resonance 

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
!$omp   shared ( dfalm, Dr, Qr, Di, Qi ) &
!$omp   private ( i, l, m )
     do i = 0,lloopmax
       call n2lm(i,l,m)
       dfalm(1,l,m) = complex(Dr(i)-Qr(i), Di(i)-Qi(i))
     end do
!$omp end parallel do


     call alm2map(nside, llmax, llmax, dfalm, map2 )

!$omp   parallel do &
!$omp   shared ( dfalm, Dr, Qr, Di, Qi ) &
!$omp   private ( i, l, m )
     do i = 0,12*nside*nside-1
       noipix = 0.000004*NoiseMap(i)*NoiseMap(i)
       Map2(i,1)=Map2(i,1)/noipix
     end do
!$omp end parallel do

     call map2alm(nside, llmax, llmax, map2, dfalm, z, dw8 ) 


!$omp   parallel do &
!$omp   shared ( dfQr, dfQi, dfalm ) &
!$omp   private ( i, l, m )
     do i = 0,lloopmax
       call n2lm(i,l,m)
       dfQr(i)=real(dfalm(1,l,m))
       dfQi(i)=aimag(dfalm(1,l,m))
     end do
!$omp end parallel do

 
!$omp   parallel do &
!$omp   shared ( Palmrdot, Palmidot, Dr, Di, SMapr, SMapi, Qr, Qi, Nl ) &
!$omp   private ( i, l, m )

       do i=0,lloopmax
         call n2lm(i,l,m)
         if(m.ne.0) then 
           Palmrdot(i)  = 2.0*RMapr(i) - 2.0*dfQr(i) !(Dr(i) - Qr(i))/Nl(l) 
           Palmidot(i)  = 2.0*RMapi(i) - 2.0*dfQi(i) !(Di(i) - Qi(i))/Nl(l) 
         else 
           Palmrdot(i)  = 1.0*RMapr(i) - 1.0*dfQr(i) !(Dr(i) - Qr(i))/Nl(l)
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

   call cpu_time(timeend)
   write(*,*) 'Time = ',timeend-timestart

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

end subroutine anisotropic


   


