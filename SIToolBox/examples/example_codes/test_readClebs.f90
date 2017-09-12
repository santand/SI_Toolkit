! Package : SI Toolkit
! Version : Beta / V1.0
! Date    : 01.04.2017   (UW Madison)
! Code    : Example

! Date    : 03.07.2017   (Example Code, written in UW Madison)

 
   integer :: recno
   real*8 :: cleb


   open(1,file='../data/Clebs_Lmax_2_lmax_01024.dat',access='direct',recl=64, action='read',status="OLD")
   call Clebsch2OneD(2,0,1000,1001,50,1024,recno)
   read(1,rec=recno)clb
   write(*,*)'2  0  1000  1001  50',clb
   close(1)


end program

