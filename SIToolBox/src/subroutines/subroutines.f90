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
   real(dp) :: Sum1,Smat,Smattot,Sum1i,Smati,Smatx
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

            call Smat1(ALMll,jl,jm,jl,jm,LMAX,llMAX,SMatx,Clebs)

            Sum1 = Sum1 + (bmap(j)*Smat - bmapi(j)*Smati)/Smatx
            Sum1i = Sum1i + (bmap(j)*Smati + bmapi(j)*Smat)/Smatx
!           end if
          end do
       end do

       call Smat1(ALMll,il,im,il,im,LMAX,llMAX,SMat,Clebs)

       call n2lm(i,il,im)                                                  ! il im
       call Sii(0,0,il,il,im,llmax,recno)                                  ! jl jm


       Sum1  = Sum1/(ALMll(0,0,il,il)*Clebs(recno)*int((-1)**im))     !il im
       Sum1i = Sum1i/(ALMll(0,0,il,il)*Clebs(recno)*int((-1)**im))    !jl jm    need to check


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
           call Sii(L,abs(M),il,jl,-im,llmax,recno)
           cleb = int((-1)**(il+jl-L))*Clebs(recno)
         else
           call Sii(L,abs(M),il,jl,-im,llmax,recno)
           cleb = Clebs(recno)
         end if

         if(L.eq.0) then
           Sum1 = Sum1 + ALMll(L,abs(M),il,jl)*cleb*int((-1)**im)
         else
           Sum1 = Sum1 + ALMll(L,abs(M),il,jl)*cleb*int((-1)**im)
         endif
       end if
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
           call Sii(L,abs(M),il,jl,-im,llmax,recno)
           cleb = Clebs(recno)
         else if(M.lt.0) then
           call Sii(L,abs(M),il,jl,-im,llmax,recno)
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

             if(m2 .gt. llmax) goto 109

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

109          continue             

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
!! Biposh Calculation 
!! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

subroutine CalcBipoSH(almr,almi,lmax,llmax,ALMll,ALMli,Clebs)

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
   real(dp) :: ALMll(0:LMAX,0:LMAX,0:llMAX,-LMAX:LMAX) !-LMAX:LMAX)
   real(dp) :: ALMli(0:LMAX,0:LMAX,0:llMAX,-LMAX:LMAX) !-LMAX:LMAX)
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

!           if(h-k .ge. 0) then
             ALMll(i,j,k,h-k) = almllr
             ALMli(i,j,k,h-k) = almlli
!           end if
  
!           if((i.eq.1).and.(abs(k-h).lt.2))write(*,*)i,j,k,k-h,ALMll(i,j,k,k-h),ALMli(i,j,k,k-h) 
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

subroutine Clebsch2OneD(L,M,l1,l2,m1,lm,Si)

   integer L,M,lm
   integer l1,l2,m1,m11
   integer Si

   Si =(L*(L+1)/2+M)*(2*L+1)*((lm+1)*(lm+1)-0)
   Si = Si + (l2-(l1-L))*((lm+1)*(lm+1)-0) + l1*l1+m1+l1
   Si = Si+1

   return

end subroutine