FasdUAS 1.101.10   ��   ��    k             l     ��  ��     	 Guan Gui     � 	 	    G u a n   G u i   
  
 l     ��  ��           �           l     ��������  ��  ��        j     �� �� 0 
scriptname 
scriptName  m        �    s k y p e c a l l      l          j    �� �� (0 trytolaunchskypein tryToLaunchSkypeIn  m    ���� <  
  sec     �      s e c      j    �� �� $0 acceptablestatus acceptableStatus  J          ! " ! m     # # � $ $ " U S E R S T A T U S   O N L I N E "  % & % m     ' ' � ( (  U S E R S T A T U S   A W A Y &  ) * ) m    	 + + � , ,  U S E R S T A T U S   D N D *  -�� - m   	 
 . . � / / ( U S E R S T A T U S   I N V I S I B L E��     0 1 0 l     ��������  ��  ��   1  2 3 2 i     4 5 4 I      ��������  0 getcurrenttime getCurrentTime��  ��   5 O      6 7 6 L    
 8 8 I   	�� 9��
�� .sysoexecTEXT���     TEXT 9 m     : : � ; ; \ p e r l   - e   ' u s e   T i m e : : H i R e s   q w ( t i m e ) ;   p r i n t   t i m e '��   7 m     ��
�� misccura 3  < = < l     ��������  ��  ��   =  > ? > i     @ A @ I      �� B���� 0 sendmsg sendMsg B  C D C o      ���� 0 nm   D  E F E o      ���� 0 t   F  G�� G o      ���� 0 d  ��  ��   A k     b H H  I J I O      K L K r     M N M ?     O P O l    Q���� Q I   �� R��
�� .corecnte****       **** R l    S���� S 6    T U T 2    ��
�� 
prcs U =    V W V 1   	 ��
�� 
bnid W m     X X � Y Y 0 c o m . G r o w l . G r o w l H e l p e r A p p��  ��  ��  ��  ��   P m    ����   N o      ���� 0 	isrunning 	isRunning L m      Z Z�                                                                                  sevs  alis    �  Macintosh HD               ɤ+�H+  '�System Events.app                                              *,6˝�u        ����  	                CoreServices    ɣ�      ˝4�    '�'�'�  =Macintosh HD:System: Library: CoreServices: System Events.app   $  S y s t e m   E v e n t s . a p p    M a c i n t o s h   H D  -System/Library/CoreServices/System Events.app   / ��   J  [ \ [ l   ��������  ��  ��   \  ]�� ] Z    b ^ _���� ^ o    ���� 0 	isrunning 	isRunning _ O    ^ ` a ` k   & ] b b  c d c r   & + e f e J   & ) g g  h�� h o   & '���� 0 nm  ��   f l      i���� i o      ���� ,0 allnotificationslist allNotificationsList��  ��   d  j k j r   , 1 l m l J   , / n n  o�� o o   , -���� 0 nm  ��   m l      p���� p o      ���� 40 enablednotificationslist enabledNotificationsList��  ��   k  q r q l  2 2��������  ��  ��   r  s t s I  2 ?���� u
�� .registernull��� ��� null��   u �� v w
�� 
appl v m   4 5 x x � y y 
 S k y p e w �� z {
�� 
anot z o   6 7���� ,0 allnotificationslist allNotificationsList { �� | }
�� 
dnot | o   8 9���� 40 enablednotificationslist enabledNotificationsList } �� ~��
�� 
iapp ~ m   : ;   � � � 
 S k y p e��   t  � � � l  @ @��������  ��  ��   �  � � � I  @ [���� �
�� .notifygrnull��� ��� null��   � �� � �
�� 
name � o   D E���� 0 nm   � �� � �
�� 
titl � o   H I���� 0 t   � �� � �
�� 
desc � o   L M���� 0 d   � �� � �
�� 
appl � m   N Q � � � � � 
 S k y p e � �� ���
�� 
iapp � m   R U � � � � � 
 S k y p e��   �  ��� � l  \ \��������  ��  ��  ��   a 5    #�� ���
�� 
capp � m     ! � � � � � 0 c o m . G r o w l . G r o w l H e l p e r A p p
�� kfrmID  ��  ��  ��   ?  � � � l     ��������  ��  ��   �  � � � i     � � � I      �� ����� 0 replacetext replaceText �  � � � o      ���� 0 find   �  � � � o      ���� 0 replace   �  ��� � o      ���� 0 subject  ��  ��   � k     & � �  � � � r      � � � n      � � � 1    ��
�� 
txdl � 1     ��
�� 
ascr � o      ���� 0 prevtids prevTIDs �  � � � r     � � � o    ���� 0 find   � n       � � � 1    
��
�� 
txdl � 1    ��
�� 
ascr �  � � � r     � � � n     � � � 2   ��
�� 
citm � o    ���� 0 subject   � o      ���� 0 subject   �  � � � l   ��������  ��  ��   �  � � � r     � � � o    ���� 0 replace   � n       � � � 1    ��
�� 
txdl � 1    ��
�� 
ascr �  � � � r     � � � b     � � � m     � � � � �   � o    ���� 0 subject   � o      ���� 0 subject   �  � � � r    # � � � o    ���� 0 prevtids prevTIDs � n       � � � 1     "��
�� 
txdl � 1     ��
�� 
ascr �  � � � l  $ $��������  ��  ��   �  ��� � L   $ & � � o   $ %���� 0 subject  ��   �  � � � l     ��������  ��  ��   �  � � � i    � � � I      �� ����� 0 splitstring splitString �  � � � o      ���� 0 astring aString �  �� � o      �~�~ 0 	delimiter  �  ��   � k     ' � �  � � � r      � � � J     �}�}   � o      �|�| 0 retval retVal �  � � � r    
 � � � n    � � � 1    �{
�{ 
txdl � 1    �z
�z 
ascr � o      �y�y 0 prevdelimiter prevDelimiter �  � � � I   �x ��w
�x .ascrcmnt****      � **** � o    �v�v 0 	delimiter  �w   �  � � � r     � � � J     � �  ��u � o    �t�t 0 	delimiter  �u   � n      � � � 1    �s
�s 
txdl � 1    �r
�r 
ascr �  � � � r     � � � n     � � � 2    �q
�q 
citm � o    �p�p 0 astring aString � o      �o�o 0 retval retVal �  � � � r    $ � � � o     �n�n 0 prevdelimiter prevDelimiter � n      � � � 1   ! #�m
�m 
txdl � 1     !�l
�l 
ascr �  ��k � L   % ' � � o   % &�j�j 0 retval retVal�k   �  � � � l     �i�h�g�i  �h  �g   �    i    ! I      �f�e�d�f 0 dismiss_skype_api_security  �e  �d   O     D O    C Z    B	�c�b I   �a
�`
�a .coredoexbool       obj 
 l   �_�^ n     4    �]
�] 
radB m     � F A l l o w   t h i s   a p p l i c a t i o n   t o   u s e   S k y p e n     4    �\
�\ 
rgrp m    �[�[  4    �Z
�Z 
cwin m     � $ S k y p e   A P I   S e c u r i t y�_  �^  �`  	 k    >  I   *�Y�X
�Y .prcsclicuiel    ��� uiel n    & 4   # &�W
�W 
radB m   $ % � F A l l o w   t h i s   a p p l i c a t i o n   t o   u s e   S k y p e n    # !  4     #�V"
�V 
rgrp" m   ! "�U�U ! 4     �T#
�T 
cwin# m    $$ �%% $ S k y p e   A P I   S e c u r i t y�X   &'& I  + 0�S(�R
�S .sysodelanull��� ��� nmbr( m   + ,)) ?��������R  ' *�Q* I  1 >�P+�O
�P .prcsclicuiel    ��� uiel+ n   1 :,-, 4   5 :�N.
�N 
butT. m   6 9// �00  O K- 4   1 5�M1
�M 
cwin1 m   3 422 �33 $ S k y p e   A P I   S e c u r i t y�O  �Q  �c  �b   4    �L4
�L 
pcap4 m    55 �66 
 S k y p e m     77�                                                                                  sevs  alis    �  Macintosh HD               ɤ+�H+  '�System Events.app                                              *,6˝�u        ����  	                CoreServices    ɣ�      ˝4�    '�'�'�  =Macintosh HD:System: Library: CoreServices: System Events.app   $  S y s t e m   E v e n t s . a p p    M a c i n t o s h   H D  -System/Library/CoreServices/System Events.app   / ��   898 l     �K�J�I�K  �J  �I  9 :;: i   " %<=< I      �H>�G�H 0 logwrite logWrite> ?�F? o      �E�E 0 textoferror textOfError�F  �G  = k     B@@ ABA l     �DCD�D  C 6 0 Establish the name and location of the log file   D �EE `   E s t a b l i s h   t h e   n a m e   a n d   l o c a t i o n   o f   t h e   l o g   f i l eB FGF r     HIH m     JJ �KK * a p p l e s c r i p t _ d e b u g . l o gI o      �C�C 0 namelogfile nameLogFileG LML r    NON b    PQP l   R�B�AR I   �@ST
�@ .earsffdralis        afdrS m    �?
�? afdmdeskT �>U�=
�> 
rtypU m    �<
�< 
TEXT�=  �B  �A  Q o    �;�; 0 namelogfile nameLogFileO o      �:�: 0 	pathtolog 	pathToLogM VWV l   �9XY�9  X 8 2 Format the error data and save it to the log file   Y �ZZ d   F o r m a t   t h e   e r r o r   d a t a   a n d   s a v e   i t   t o   t h e   l o g   f i l eW [\[ r    !]^] b    _`_ b    aba b    cdc b    efe n    ghg 1    �8
�8 
dstrh l   i�7�6i I   �5�4�3
�5 .misccurdldt    ��� null�4  �3  �7  �6  f 1    �2
�2 
tab d o    �1�1 0 textoferror textOfErrorb o    �0
�0 
ret ` o    �/
�/ 
ret ^ o      �.�. 0 	texttolog 	textToLog\ jkj I  " ,�-lm
�- .rdwropenshor       filel 4   " &�,n
�, 
filen o   $ %�+�+ 0 	pathtolog 	pathToLogm �*o�)
�* 
permo m   ' (�(
�( boovtrue�)  k pqp I  - 9�'rs
�' .rdwrwritnull���     ****r o   - .�&�& 0 	texttolog 	textToLogs �%tu
�% 
refnt 4   / 3�$v
�$ 
filev o   1 2�#�# 0 	pathtolog 	pathToLogu �"w�!
�" 
wratw m   4 5� 
�  rdwreof �!  q x�x I  : B�y�
� .rdwrclosnull���     ****y 4   : >�z
� 
filez o   < =�� 0 	pathtolog 	pathToLog�  �  ; {|{ l     ����  �  �  | }�} i   & )~~ I     ���
� .aevtoappnull  �   � ****� o      �� 0 argv  �   k    ��� ��� r     ��� m     �� ���  � o      �� 0 notify_title  � ��� r    ��� m    �� ���  � o      �� 0 
notify_msg  � ��� r    ��� m    	�� ���  � o      �� 0 res  � ��� O   4��� k   3�� ��� r    ��� m    �� ���  C O M M A N D _ P E N D I N G� o      �� 
0 status  � ��� l   ����  �  �  � ��� r    ��� n   ��� I    ���
�  0 getcurrenttime getCurrentTime�  �
  �  f    � o      �	�	 0 	starttime 	startTime� ��� r    ��� o    �� 0 	starttime 	startTime� o      �� 0 currtime currTime� ��� V     ���� k   ; ��� ��� Q   ; ����� k   > ��� ��� r   > O��� I  > M���
� .sendskypnull��� ��� null�  � ���
� 
cmnd� m   @ A�� ���  G E T   U S E R S T A T U S� ���
� 
scrp� o   B G�� 0 
scriptname 
scriptName�  � o      � �  
0 status  � ��� l  P P��������  ��  ��  � ��� Z   P }������ =  P U��� o   P Q���� 
0 status  � m   Q T�� ���  C O M M A N D _ P E N D I N G� n  X ]��� I   Y ]�������� 0 dismiss_skype_api_security  ��  ��  �  f   X Y� ��� =  ` e��� o   ` a���� 
0 status  � m   a d�� ��� $ U S E R S T A T U S   O F F L I N E� ���� I  h y�����
�� .sendskypnull��� ��� null��  � ����
�� 
cmnd� m   j m�� ��� * S E T   U S E R S T A T U S   O N L I N E� �����
�� 
scrp� o   n s���� 0 
scriptname 
scriptName��  ��  ��  � ���� I  ~ ������
�� .sysodelanull��� ��� nmbr� m   ~ ��� ?�      ��  ��  � R      ����
�� .ascrerr ****      � ****� o      ���� 0 errtext errText� �����
�� 
errn� o      ���� 0 errnum errNum��  � Z   � ������ =   � ���� o   � ����� 0 errnum errNum� m   � �������� I  � ������
�� .sysodelanull��� ��� nmbr� m   � ����� ��  � ��� =   � ���� o   � ����� 0 errnum errNum� m   � ������?� ���� k   � ��� ��� r   � ���� m   � ��� ��� d P l e a s e   l o g   i n   t o   y o u r   s k y p e   a c c o u n t   t o   m a k e   a   c a l l� o      ���� 0 
notify_msg  � ����  S   � ���  ��  � k   � ��� ��� r   � ���� b   � ���� m   � ��� ���  E r r o r :  � o   � ����� 0 errtext errText� o      ���� 0 
notify_msg  � ����  S   � ���  � ��� l  � ���������  ��  ��  �  ��  r   � � n  � � I   � ���������  0 getcurrenttime getCurrentTime��  ��    f   � � o      ���� 0 currtime currTime��  � F   $ : l  $ -���� A   $ -	 \   $ '

 o   $ %���� 0 currtime currTime o   % &���� 0 	starttime 	startTime	 o   ' ,���� (0 trytolaunchskypein tryToLaunchSkypeIn��  ��   l  0 8���� H   0 8 E  0 7 o   0 5���� $0 acceptablestatus acceptableStatus o   5 6���� 
0 status  ��  ��  �  l  � ���������  ��  ��   �� Z   �3���� l  � ����� E  � � o   � ����� $0 acceptablestatus acceptableStatus l  � ����� I  � �����
�� .sendskypnull��� ��� null��   ��
�� 
cmnd m   � � �  G E T   U S E R S T A T U S ����
�� 
scrp o   � ����� 0 
scriptname 
scriptName��  ��  ��  ��  ��   k   �/  !  O   � �"#" O   � �$%$ r   � �&'& m   � ���
�� boovtrue' 1   � ���
�� 
pvis% 4   � ���(
�� 
pcap( m   � �)) �** 
 S k y p e# m   � �++�                                                                                  sevs  alis    �  Macintosh HD               ɤ+�H+  '�System Events.app                                              *,6˝�u        ����  	                CoreServices    ɣ�      ˝4�    '�'�'�  =Macintosh HD:System: Library: CoreServices: System Events.app   $  S y s t e m   E v e n t s . a p p    M a c i n t o s h   H D  -System/Library/CoreServices/System Events.app   / ��  ! ,-, r   �./. m   � 00 �11  C a l l   E r r o r/ o      ���� 0 notify_title  - 232 r  454 n 676 I  ��8���� 0 replacetext replaceText8 9:9 m  ;; �<<   : =>= m  
?? �@@  > A��A c  
BCB o  
���� 0 argv  C m  ��
�� 
TEXT��  ��  7  f  5 o      ���� 0 q  3 D��D r  /EFE I -����G
�� .sendskypnull��� ��� null��  G ��HI
�� 
cmndH b  !JKJ m  LL �MM 
 C A L L  K o   ���� 0 q  I ��N��
�� 
scrpN o  "'���� 0 
scriptname 
scriptName��  F o      ���� 0 res  ��  ��  ��  ��  � m    OO�                                                                                  SKYP  alis    H  Macintosh HD               ɤ+�H+  '�	Skype.app                                                      %��ˤ�R        ����  	                Applications    ɣ�      ˤ[�    '�  $Macintosh HD:Applications: Skype.app   	 S k y p e . a p p    M a c i n t o s h   H D  Applications/Skype.app  / ��  � PQP l 55��������  ��  ��  Q RSR l 55��TU��  T  On fail or error   U �VV   O n   f a i l   o r   e r r o rS W��W Z  5�XYZ��X G  5D[\[ E 5:]^] o  56���� 0 res  ^ m  69__ �`` 
 E R R O R\ E =Baba o  =>���� 0 res  b m  >Acc �dd  F A I LY k  Gtee fgf r  GRhih n GPjkj I  HP��l���� 0 splitstring splitStringl mnm o  HI���� 0 res  n o��o m  ILpp �qq  :  ��  ��  k  f  GHi o      ���� 0 
notify_msg  g rsr Q  Situvt r  V^wxw n  V\yzy 4  W\��{
�� 
cobj{ m  Z[���� z o  VW���� 0 
notify_msg  x o      ���� 0 
notify_msg  u R      ������
�� .ascrerr ****      � ****��  ��  v r  fi|}| o  fg���� 0 res  } o      ���� 0 
notify_msg  s ~~ I  jr������� 0 sendmsg sendMsg� ��� o  kl���� 0 notify_title  � ��� o  lm���� 0 notify_title  � ���� o  mn���� 0 
notify_msg  ��  ��   ���� l ss������  � 3 - if not fail, but there is a message, show it   � ��� Z   i f   n o t   f a i l ,   b u t   t h e r e   i s   a   m e s s a g e ,   s h o w   i t��  Z ��� > w|��� o  wx���� 0 
notify_msg  � m  x{�� ���  � ���� I  �������� 0 sendmsg sendMsg� ��� o  ������ 0 notify_title  � ��� o  ������ 0 notify_title  � ���� o  ������ 0 
notify_msg  ��  ��  ��  ��  ��  �       �� �~��������0�������}�|�{�  � �z�y�x�w�v�u�t�s�r�q�p�o�n�m�l�k�j�i�h�g�z 0 
scriptname 
scriptName�y (0 trytolaunchskypein tryToLaunchSkypeIn�x $0 acceptablestatus acceptableStatus�w  0 getcurrenttime getCurrentTime�v 0 sendmsg sendMsg�u 0 replacetext replaceText�t 0 splitstring splitString�s 0 dismiss_skype_api_security  �r 0 logwrite logWrite
�q .aevtoappnull  �   � ****�p 0 notify_title  �o 0 
notify_msg  �n 0 res  �m 
0 status  �l 0 	starttime 	startTime�k 0 currtime currTime�j 0 q  �i  �h  �g  �~ <� �f��f �   # ' + .� �e 5�d�c���b�e  0 getcurrenttime getCurrentTime�d  �c  �  � �a :�`
�a misccura
�` .sysoexecTEXT���     TEXT�b � �j U� �_ A�^�]���\�_ 0 sendmsg sendMsg�^ �[��[ �  �Z�Y�X�Z 0 nm  �Y 0 t  �X 0 d  �]  � �W�V�U�T�S�R�W 0 nm  �V 0 t  �U 0 d  �T 0 	isrunning 	isRunning�S ,0 allnotificationslist allNotificationsList�R 40 enablednotificationslist enabledNotificationsList�  Z�Q��P X�O�N ��M�L x�K�J�I �H�G�F�E�D � ��C�B
�Q 
prcs�  
�P 
bnid
�O .corecnte****       ****
�N 
capp
�M kfrmID  
�L 
appl
�K 
anot
�J 
dnot
�I 
iapp�H 
�G .registernull��� ��� null
�F 
name
�E 
titl
�D 
desc�C 

�B .notifygrnull��� ��� null�\ c� *�-�[�,\Z�81j jE�UO� E)���0 9�kvE�O�kvE�O*������� O*a �a �a ��a �a a  OPUY h� �A ��@�?���>�A 0 replacetext replaceText�@ �=��= �  �<�;�:�< 0 find  �; 0 replace  �: 0 subject  �?  � �9�8�7�6�9 0 find  �8 0 replace  �7 0 subject  �6 0 prevtids prevTIDs� �5�4�3 �
�5 
ascr
�4 
txdl
�3 
citm�> '��,E�O���,FO��-E�O���,FO�%E�O���,FO�� �2 ��1�0���/�2 0 splitstring splitString�1 �.��. �  �-�,�- 0 astring aString�, 0 	delimiter  �0  � �+�*�)�(�+ 0 astring aString�* 0 	delimiter  �) 0 retval retVal�( 0 prevdelimiter prevDelimiter� �'�&�%�$
�' 
ascr
�& 
txdl
�% .ascrcmnt****      � ****
�$ 
citm�/ (jvE�O��,E�O�j O�kv��,FO��-E�O���,FO�� �#�"�!��� �# 0 dismiss_skype_api_security  �"  �!  �  � 7�5����$�)�2�/
� 
pcap
� 
cwin
� 
rgrp
� 
radB
� .coredoexbool       obj 
� .prcsclicuiel    ��� uiel
� .sysodelanull��� ��� nmbr
� 
butT�  E� A*��/ 9*��/�k/��/j  '*��/�k/��/j O�j O*��/�a /j Y hUU� �=������ 0 logwrite logWrite� ��� �  �� 0 textoferror textOfError�  � ����� 0 textoferror textOfError� 0 namelogfile nameLogFile� 0 	pathtolog 	pathToLog� 0 	texttolog 	textToLog� J����
�	��������� ������
� afdmdesk
� 
rtyp
� 
TEXT
�
 .earsffdralis        afdr
�	 .misccurdldt    ��� null
� 
dstr
� 
tab 
� 
ret 
� 
file
� 
perm
� .rdwropenshor       file
� 
refn
� 
wrat
�  rdwreof �� 
�� .rdwrwritnull���     ****
�� .rdwrclosnull���     ****� C�E�O���l �%E�O*j �,�%�%�%�%E�O*�/�el O��*�/��� O*�/j � ����������
�� .aevtoappnull  �   � ****�� 0 argv  ��  � �������� 0 argv  �� 0 errtext errText�� 0 errnum errNum� 3���������O�������������������������������������+��)��0;?������L_cp������������� 0 notify_title  �� 0 
notify_msg  �� 0 res  �� 
0 status  ��  0 getcurrenttime getCurrentTime�� 0 	starttime 	startTime�� 0 currtime currTime
�� 
bool
�� 
cmnd
�� 
scrp�� 
�� .sendskypnull��� ��� null�� 0 dismiss_skype_api_security  
�� .sysodelanull��� ��� nmbr�� 0 errtext errText� ������
�� 
errn�� 0 errnum errNum��  �������?
�� 
pcap
�� 
pvis
�� 
TEXT�� 0 replacetext replaceText�� 0 q  �� 0 splitstring splitString
�� 
cobj��  ��  �� 0 sendmsg sendMsg����E�O�E�O�E�O�%�E�O)j+ 	E�O�E�O �h��b  	 b  ��& L*���b   a  E�O�a   
)j+ Y �a   *�a �b   a  Y hOa j W 4X  �a   a j Y �a   a E�OY a �%E�OO)j+ 	E�[OY�_Ob  *�a �b   a   Ra  *a  a !/ 	e*a ",FUUOa #E�O)a $a %�a &&m+ 'E` (O*�a )_ (%�b   a  E�Y hUO�a *
 	�a +�& 2)�a ,l+ -E�O �a .l/E�W 
X / 0�E�O*���m+ 1OPY �a 2 *���m+ 1Y h� ��� 6 C A L L   2 8 8 0 4 5   S T A T U S   U N P L A C E D� ��� " U S E R S T A T U S   O N L I N E� ���   1 3 3 6 5 0 4 1 2 2 . 0 7 4 5 9� ���   1 3 3 6 5 0 4 1 2 2 . 6 2 7 1 7� ���  t e t s�}  �|  �{  ascr  ��ޭ