////// NIDE26 MAPSYS (STRIPPER VERSION)

// don't forget to change these with each update!!
::g_iStripperVersion <- 1.0;
m_szStripper <- "\x07FFCC00 ELTRAFIXES: This server is running \x07FFFFFFSallyPatch "+g_iStripperVersion.tostring()+"\x07FFCC00."


// ⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⡀⠄⢀⠄⠄⡀⠄⡀⢀⠄⡀⢀⠄⡀⢀⠄⡀⢀⠄⢀⠄⢀⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠄⠐⠈⠄⢈⠄⠈⠄⠁⠈⡀⠁⠈⠄⠁⢀⠠⠄⠄⠂⠄⠄⠠⠄⠠⡠⢠⠠⠠⡀⠄⡠⠠⡐⠄⠠⠄⡀⠈⡀⠈⠄⠐⠄⠐⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠈⠄⠐⠈⠄⢀⠈⠄⢁⠠⠄⢀⠁⠄⠁⡀⠠⠄⠄⠂⠐⠄⡄⣌⢢⢳⢨⢌⢖⡈⡌⠌⠄⠄⠄⠄⠂⠄⠄⠄⠄⠁⠄⠂⠄⠐⠄⠄⡀⠈⠄⠄⠁⠄⠄⠂⠄⠐⠄⠄⠄
// ⠄⠈⠄⡁⠠⠈⢀⠄⢁⠄⠄⠐⠄⠠⠄⠂⠄⠄⠐⠄⢂⠐⠩⡘⠔⠕⡑⣑⠡⡢⡫⠪⠔⠕⢊⠄⡀⠠⠐⠄⠂⠄⠂⠁⠄⠁⢀⠐⠄⠄⠄⡀⠂⠄⠄⠄⠄⠄⢀⠄⠄⠄
// ⠄⠈⡀⠠⠄⠂⡀⠄⠠⠄⠐⠄⢁⠄⠂⠁⠐⠄⠂⢅⠢⠨⠐⠠⠨⡀⡊⣊⡳⡕⡖⡵⡨⢴⠱⡱⡢⠄⠄⠂⢈⠄⠐⠄⠁⠠⠄⢀⠠⠄⠁⠄⠄⢀⠄⠄⡀⠈⠄⠄⠄⠄
// ⠄⠐⢀⠄⠂⠠⠄⠐⠄⠂⠁⡈⢀⠐⠈⡀⢁⠨⡐⠐⡈⠄⠂⢅⠁⡂⠪⠚⢜⠔⡕⣕⢝⠆⢅⡑⣜⠌⠄⢁⠄⠄⠁⡀⠁⡀⠄⠄⢀⠄⠠⠄⠂⠄⠄⠄⠄⠄⢀⠄⠄⠂
// ⠄⢈⠄⠄⠁⠐⠈⡀⠁⠄⢁⠠⠄⠐⠄⠄⠄⡂⡨⠢⡀⠂⡁⡔⢅⢢⢢⣜⡼⣮⣣⣥⡵⡺⣗⣯⡷⠧⠄⠂⠠⠐⠄⠠⠄⡀⠠⠐⠄⠄⡀⠠⠄⢀⠈⠄⠈⠄⠄⠄⠄⠄
// ⠄⠄⠐⠄⡁⢈⠄⠄⠂⠐⠄⠄⢈⠄⡁⡀⢅⢂⠜⡐⢄⢥⢊⢮⢲⢢⣻⢾⣯⡷⣅⢠⢄⢧⣳⡟⢈⠈⠠⠈⢀⠐⠈⠄⠄⠄⠄⢀⠐⠄⢀⠄⠄⠄⠄⠄⠂⠄⠂⠄⠠⠄
// ⠄⠐⠈⡀⠄⠠⠄⠂⡈⢀⠁⠐⡀⠠⠄⠐⢐⠐⠅⡪⡱⡹⡵⣫⢪⢣⢫⣟⡾⣟⣿⣽⡾⣿⣻⣽⣖⠐⡠⠁⠠⠄⡈⠠⠐⠄⠂⢀⠄⠂⠄⡀⠄⠄⠁⠄⢀⠠⠄⠠⠄⠄
// ⠄⢁⠐⢀⠐⠄⠌⠄⠄⡀⠂⡁⠠⠄⠂⠁⢂⠡⡡⡑⡕⣝⣕⢇⢇⠣⣳⢵⣫⢗⣯⢾⣻⣝⢗⠯⡳⢀⠐⠄⠂⠠⠄⠄⠂⢀⠁⢀⠄⠂⠁⠄⡀⠄⠁⠠⠄⠄⢀⠄⠠⠄
// ⠄⠄⠂⡀⠂⡁⠄⠡⢀⠐⠠⠄⡂⢅⠅⡌⢄⢂⢂⠮⡞⣗⢧⡓⢧⠣⣓⢟⡮⣟⡾⡽⠯⠿⠝⢎⠂⠄⡀⢁⠈⡀⠐⠄⠂⡀⠐⠄⡀⠂⠈⠄⢀⠄⠄⠠⠐⠈⠄⠄⡀⠄
// ⠄⠂⡁⠄⠂⠄⢂⠁⡀⢈⠨⠨⠐⠄⠅⢃⢁⠢⢂⠣⢣⢥⣓⠎⡁⡣⠈⢇⢻⢪⢏⡯⣏⡃⢒⠄⢀⠱⠄⠢⠄⠄⡂⠁⠠⠄⠂⠁⡀⠄⠁⠐⠄⡀⠄⠠⠄⠠⠐⠄⠄⡀
// ⠄⡁⠄⠂⡁⢐⠄⡂⠄⠄⢀⠂⠠⠁⢈⠠⠄⠁⣇⠨⣒⢕⠗⢑⡸⣕⢕⢄⢂⠡⠉⠏⢯⠻⠅⡐⡀⠔⠡⠂⡁⢂⠂⡈⠠⠐⠈⢀⠠⠄⠂⠁⡀⠄⠄⠄⠐⠄⠠⠐⠄⠄
// ⠄⠄⠂⠄⢂⢐⢐⠠⠅⡐⠐⡀⠌⠰⡐⡸⡜⠄⡈⠪⡸⡪⡎⣔⢺⣜⢕⢅⠂⠐⠄⠄⡀⠄⠂⡀⠂⡁⠨⠄⠄⠂⠠⠄⡂⠐⠈⢀⠠⠐⠄⠁⡀⠠⠐⠄⠄⠂⠄⠄⠂⠄
// ⠄⢌⠄⡁⠄⠄⠄⠐⢀⠄⡂⢂⠣⠁⠜⠸⠸⠸⡈⡀⠂⡍⢝⢎⢏⡪⣫⣯⢿⣲⣶⣦⣄⡠⠄⢀⠂⠠⢈⠈⠨⠄⠅⡐⢀⠈⠠⠄⠄⠐⠈⢀⠄⠄⠄⠂⠁⡀⠁⡀⠐⠄
// ⠈⠠⠠⠐⢀⠁⡐⢈⠄⠄⠠⠄⠂⢨⠄⠨⣘⠈⣐⠼⢵⣳⢕⢽⢵⢽⣻⡾⣟⣿⢷⣷⢿⣽⣢⠐⢈⠐⠄⠄⢁⠈⠄⠠⠄⠂⠐⠄⠂⡀⢁⠄⠄⠐⠈⠄⠄⠠⠄⠠⠐⠄
// ⠄⠡⠄⠁⠂⠁⡀⠄⢐⠐⠄⠂⠌⠜⢪⡲⠌⡆⠠⠈⠨⠠⡣⣳⣻⣻⣯⣿⣻⣽⣿⣻⣟⣷⣻⡂⠢⠨⠐⡁⠄⢀⠂⠐⢈⠄⡁⢈⠄⠄⠠⠄⠐⢀⠈⠠⠐⠄⠐⠄⠄⠄
// ⠈⠠⠈⠠⠈⡀⠄⠐⡐⢈⠠⡁⢞⠐⠄⢁⠨⡐⡡⡠⡣⡩⣺⡺⢽⡽⣾⣳⡿⣽⣾⢿⣽⣟⣾⡃⠄⠁⠄⠂⠐⠄⠄⢁⠠⠄⠄⠠⠄⠂⠐⠈⠠⠄⠐⠄⠂⢈⠄⠂⠄⠂
// ⠄⠡⢈⠄⡁⠄⠂⠁⡀⢀⠐⡀⠐⡀⠱⡒⢐⢸⡰⢠⠱⡸⣕⡯⣳⢽⡯⣷⣟⡿⣾⢿⡷⣿⣞⣗⠄⡁⠄⠡⠈⡀⠂⡀⠄⠂⠄⠂⡀⢁⠈⡀⠂⠁⡈⠄⡁⠠⠐⠈⡀⠂
// ⠈⠄⢂⠐⡀⠂⠈⡀⠄⠨⢂⢐⢀⢂⠕⡀⠨⡢⢩⢣⢫⡪⡷⡽⣝⣗⣯⢷⢯⢿⡽⣟⣿⣽⣾⣳⡈⠠⠈⡀⠂⠄⠄⠄⠄⠂⠡⠐⡀⠄⠠⠄⠂⠁⡀⠄⠠⠄⠂⠁⡀⠄
// ⠠⠈⠄⢐⠄⠅⠂⢀⠄⡁⠐⢀⠐⠁⠈⠄⢂⢇⠅⡪⡪⣞⣯⢯⣗⡷⡯⡫⡫⡯⣟⣯⣿⢷⣟⡷⡅⠂⢁⠄⠄⡁⠄⠡⢈⠈⠄⠡⠐⡈⠄⡈⢀⠁⠠⠄⠂⠐⠈⡀⢀⠄
// ⠄⠅⡈⠄⠂⡈⠠⠄⠂⠄⠄⠐⠄⠐⠄⡁⢐⢅⠕⢮⢪⢷⢽⡽⡾⣽⣻⡢⠨⣫⢯⣿⡾⣿⢿⣽⣳⠈⠠⠐⡀⢐⠈⠄⠂⠄⠅⠌⡐⠄⡂⢐⠠⢈⠐⡈⠄⡁⠂⠄⠠⠄
// ⠄⠂⠠⠐⠄⠄⠐⠄⠄⠁⠄⡁⠄⢁⠡⠄⠐⠌⡎⡎⣕⢽⢵⣻⢯⡷⡯⡯⡂⠪⡻⡺⢿⢻⠿⡻⡚⠌⠄⠡⠠⡂⢔⢈⢄⠁⡂⠡⠈⠌⠢⡑⡐⢄⠂⡐⢀⠂⠡⠈⠄⠂
// ⠄⡈⠄⠂⢁⠐⠈⡀⠈⠄⠄⠄⠄⠄⢀⠈⡀⠅⡊⢎⢮⡺⡽⣞⣯⢿⠽⠝⠠⢁⠐⡈⠢⠑⢌⠢⡊⠌⠠⠁⡁⢂⢑⠐⠄⠕⠨⡂⢅⠨⠄⡂⠌⠂⠅⡂⠂⠌⡐⢀⠂⠠
// ⠄⠄⠂⡈⢀⠐⠄⠄⠄⢀⠠⠐⠄⠄⠄⠠⠄⠠⠈⠜⢴⡹⣝⢗⠫⠡⠡⠁⠅⡐⢈⠠⢁⠑⠄⡁⡂⠕⢌⠄⠄⠄⠠⠑⠨⡈⠄⠂⡂⠅⡑⠄⡊⠌⡐⠄⠅⠡⠐⡀⢈⠄
// ⠄⠂⡁⠄⠠⠄⡁⠄⠁⠄⠄⠄⠄⠄⠠⠄⠈⡀⠈⠈⡂⠑⡁⢂⠨⠄⠅⠨⠐⡀⠂⠌⡐⠈⠄⡐⠠⡑⠅⡕⢅⠕⡄⢅⢂⠐⡈⡐⡀⢂⠂⠅⡂⠅⡂⠅⡈⠄⢁⠠⠄⠄
// ⠄⡁⠄⠐⠄⡁⠠⠐⠈⡀⠄⠄⠄⢀⠄⠂⠠⠄⠂⢁⠄⢂⠄⠂⠐⠠⠈⠠⠁⠄⡁⢂⠠⠁⠂⠄⠅⡂⡑⢌⠢⠣⡪⠢⢅⢕⠠⢐⢈⢂⠢⠡⠠⢑⠐⢅⠂⠌⠠⠄⠂⡀
// ⠄⠠⠐⠈⡀⠄⠂⡈⠄⠄⠂⠁⡈⠄⠠⠈⠄⠂⢁⠠⠐⠄⠄⢁⠈⠄⠈⠄⢂⠡⠄⠄⠐⠈⡈⠄⡑⡐⠄⠅⠅⡑⠨⢊⠪⡂⡇⢕⠰⡐⠌⠄⠅⢑⢈⠢⠨⠨⠄⠅⠠⠄
// ⠄⠂⡀⢁⠠⠐⠄⠄⠂⡀⠁⠄⠄⠂⠐⠄⢁⠈⡀⠄⠂⠁⠄⠠⠐⢀⠁⠌⠠⠐⡈⠄⡁⠐⡀⠂⡐⠨⠈⡂⢂⠠⠁⠡⢑⠱⡘⢜⢌⠪⠨⠄⠅⠂⡐⢈⠈⠄⡁⠐⢀⠄
// ⠄⠂⠠⠄⠄⠂⢁⠄⠂⡀⠂⡀⠁⠄⠁⡈⠄⠄⢀⠐⢈⠄⢂⠐⢈⠠⠐⡈⠠⢁⠐⠠⠐⠄⠂⠁⠄⠨⢐⢀⠂⠔⡈⠄⠂⠌⠌⡐⢐⠨⡀⠅⠠⠁⠄⠂⠄⠁⠄⠈⠄⠄
// ⠄⡈⠠⠐⠄⠂⠄⠄⢁⠠⠄⠄⠂⢀⠁⠄⠈⠄⡀⠂⠄⠨⠄⡂⢐⠄⡂⠐⡈⠄⠨⠄⠂⡁⢈⠄⡁⢈⠠⠐⠈⡐⠠⢈⠄⢂⠐⠄⠂⠐⢀⠁⢂⠡⠈⠄⢈⠄⠂⠁
// ⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠰⠶⢶⠶⠶⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠄⣿⠄⠄⠄⠄⠄⠄⣠⣴⢶⣤⠄⣶⣠⣶⣤⣴⣦⠄⠄⠄⠄⢠⡴⠶⣿⠄⢠⣴⢦⡄⠄⣤⣠⢴⡄⢠⣤⡤⣦⢰⡄⠄⠄⣴⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠄⣿⠄⠄⠄⠄⠄⢰⡏⠄⠐⡇⠄⣿⠋⢸⡏⠄⢹⡄⠄⠄⠄⠘⠳⠶⣄⠄⣿⠄⠄⣿⠄⣿⠁⠈⠃⢸⡏⠄⠙⠄⢻⣆⣸⠏⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠠⠶⠿⠶⠶⠄⠄⠄⠈⠻⠶⠶⠿⠄⠿⠄⠄⡷⠄⠸⠇⠄⠄⠄⠻⠶⠶⠟⠄⠹⠶⠾⠋⠄⠿⠄⠄⠄⠸⠇⠄⠄⠄⠄⣻⠏⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⢰⡟⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⢀⡀⠄⠄⠄⠄⠄⠄⠄⢀⡀⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⡀⠄⢀⡀⠄⠄⠄⠄⠄
// ⠄⠸⠇⠄⠄⡟⠛⠛⠛⠃⢸⡇⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⢸⡟⠛⠳⣆⠄⠘⠃⠄⠄⠄⠄⠄⠄⠄⠄⢰⡇⠄⠸⠇⠄⠄⠄⠄⠄
// ⠄⠄⠄⠄⢀⣧⡴⠶⠶⠄⢸⡇⢀⣴⠞⢻⡆⠄⣿⠞⠻⣦⠄⣿⠶⠛⣶⠐⢷⡀⠄⣰⠇⠄⠄⠄⢸⣇⣀⣴⠏⠄⢸⠆⢸⡷⠚⣿⠄⣰⠾⠛⢾⡇⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠄⠄⠄⢸⡇⠄⠄⠄⠄⢸⡇⢸⣇⠄⢸⣇⠄⣿⠄⠄⣿⠄⣿⠄⠄⣸⠇⠈⢷⣰⠏⠄⠄⠄⠄⢸⡏⠉⠙⣷⠄⣿⠄⢸⡇⠄⠄⠄⣿⡀⠄⣸⡇⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠄⠄⠄⠸⠇⠄⠄⠄⠄⠸⠃⠄⠙⠛⠋⠛⠄⣿⠷⠞⠋⠄⣿⠿⠾⠋⠄⠄⣸⡏⠄⠄⠄⠄⠄⠸⠷⠟⠛⠉⠄⠘⠄⠘⠃⠄⠄⠄⠈⠛⠛⠛⠃⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⣿⠄⠄⠄⠄⢿⠄⠄⠄⠄⠠⠿⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⢀⣀⣀⡀⠄⠄⢀⣀⣀⡀⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⣀⠄⠄⡀⠄⢀⣀⣠⡄⠄⠄⣀⡀⠄⠄⡀⢀⣀⠄⠄⣀⣠⣤⠄⠄⠄⠄⠄⠄⠐⠟⠉⠉⣿⠄⠐⠟⠉⠉⣿⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⣿⠄⠄⡿⠄⣿⣍⣘⠃⢰⢟⣉⡽⠇⠄⡿⠋⠹⠇⢾⣯⣁⠛⠄⠄⠄⠄⠄⠄⠄⣀⣴⠞⠃⠄⠄⣀⣴⠞⠃⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⣿⣀⣠⣷⢠⣄⣀⣽⠆⠸⣯⣁⣠⡴⠄⡇⠄⠄⠄⣤⣀⣩⡷⠄⠄⡀⠄⠄⠄⢰⣟⣠⣤⣄⠄⢰⣟⣠⣤⣄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠈⠉⠁⠁⠄⠉⠉⠁⠄⠄⠈⠉⠉⠄⠄⠁⠄⠄⠄⠈⠉⠉⠄⠄⢰⠇⠄⠄⠄⠄⠉⠉⠁⠉⠄⠄⠉⠉⠁⠉⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⣷⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⢠⡾⠛⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⣿⣀⣤⣄⠄⠄⣠⣤⣄⠄⢠⡄⠄⢠⡀⢠⣀⣤⣄⠄⣠⣤⢶⡆⠄⠄⠄⣠⣼⣧⣤⠄⢠⣀⣤⣄⠄⣀⣤⣄⡀⢀⡄⣠⣤⣀⣤⣄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⣿⠋⠄⣿⠄⣼⠋⠄⢻⠄⢺⡁⠄⣿⠄⢸⠋⠄⠛⠘⠿⠦⣬⠁⠄⠄⠄⠄⢸⡇⠄⠄⢸⠋⠄⠛⢰⡏⠄⢸⡇⢘⡿⠋⢸⡏⠄⣿⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⣿⠄⠄⢿⠄⠹⢧⣴⠟⠄⠸⣧⣤⢿⠄⢸⠄⠄⠄⠰⣦⣤⡾⠃⠄⠄⠄⠄⢸⡇⠄⠄⢸⠄⠄⠄⠘⠷⣤⡾⠃⠸⡇⠄⢸⡇⠄⢻⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠈⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⢀⠄⠄⡀⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠘⠛⢿⠟⠷⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠐⠖⠄⣿⠄⢸⣿⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⣶⣴⢶⡆⠄⣴⠶⢶⡄⢰⡆⠄⣶⡀⢰⡆⠄⠄⠄⠄⠄⠄⠄⣿⠄⠄⠄⠄⠄⠠⣦⠄⣴⡄⢠⡆⢰⡆⠄⣿⠄⢸⡇⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⣿⠁⠄⣇⢸⣏⠄⢈⡇⠈⣷⣸⠻⡇⣾⠄⠄⠄⠄⠄⠄⠄⠄⣿⠄⠄⠄⠄⠄⠄⣿⣸⠋⣇⣼⠁⢸⡇⠄⣿⠄⢸⡇⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠟⠄⠄⠿⠄⠛⠷⠟⠁⠄⠹⠃⠄⠻⠃⠄⠄⣴⠄⠄⠄⠐⠶⠿⠶⠶⠄⠄⠄⠄⠸⠏⠄⠻⠏⠄⠸⠇⠄⠿⠄⠸⠇⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠃⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⢀⡀⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⢠⡄⠄⠄⣀⣀⣀⣀⠄⢠⡄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠄⣶⠄⠄⠄⠄⠄⠄⠄⢸⡇⠄⠄⡀⠄⠄⠄⠄⠄⠄⠄⠄⠄⠘⠇⠄⠄⣿⠋⠉⠙⠃⢸⡇⠄⠄⠄⠄⠄⠄⡀⠄⠄⠄⠄⢀⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠈⠛⣿⠛⠃⣰⠟⠛⣿⠄⢸⣇⣠⡾⠃⢀⡾⢛⣛⡧⠄⠄⠄⠄⠄⠄⠄⠄⣿⠶⠶⠶⠄⢸⡇⢀⣶⠛⢻⡗⠄⣿⠟⠛⣷⠄⣿⠞⠛⢷⡀⢷⡄⠄⣼⠇⠄⠄⠄⠄⠄⠄
// ⠄⠄⣿⠄⠄⣿⡀⢀⣿⡀⢸⡟⠙⢧⡀⠸⣟⡉⢁⣠⠄⠄⠄⠄⠄⠄⠄⢀⡿⠄⠄⠄⠄⢸⡇⠸⣇⡀⣘⣇⠄⣿⠄⢀⣿⠄⣿⡀⠄⣸⠇⠈⢿⣼⠏⠄⠄⠄⠄⠄⠄⠄
// ⠄⠄⠙⠄⠄⠈⠙⠋⠉⠃⠘⠃⠄⠈⠓⠄⠉⠛⠋⠉⠄⠄⠄⠄⠄⠄⠄⠘⠇⠄⠄⠄⠄⠘⠃⠄⠉⠛⠉⠙⠄⣿⠛⠛⠁⠄⣿⠛⠛⠋⠄⠄⣸⠏⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠿⠄⠄⠄⠄⠿⠄⠄⠄⠄⠄⠟⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⢠⣤⣤⣀⠄⠄⣀⠄⠄⠄⠄⠄⠄⠄⠄⠄⢰⡆⠄⣶⠄⠄⠄⠄⠄⠄⠄⠄⢠⡆⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⣠⣤⣤⣤⣄⠄⠄⠄⠄
// ⠄⢸⠇⠈⢹⡆⠄⣈⠄⢀⢀⣀⣀⠄⢀⣀⣀⣸⠇⠄⠙⠄⠄⠄⠄⠄⠄⣀⣀⣸⡇⠄⢀⣀⣀⠄⢀⡀⠄⣀⠄⢀⡀⣀⠄⣀⣀⠄⠄⠄⠄⠄⠄⠄⢀⡟⠄⠄⠄⠄⠄⠄
// ⠄⣿⠶⢶⣿⡀⠄⣿⠄⣿⠋⠁⠟⢠⡟⠉⠉⣿⠄⠄⠄⠄⠄⠄⠄⠄⡾⠉⠉⢹⡇⢰⡟⠉⠹⡇⢸⡇⢰⢿⡄⣼⠁⣽⡟⠉⣿⠄⠄⠄⠄⠄⠄⠄⠸⡇⠄⠄⠄⠄⠄⠄
// ⠄⣿⣀⣠⣴⠟⠄⣿⠄⣿⠄⠄⠄⠘⢷⣤⣤⣿⡀⠄⠄⠄⠄⠄⠄⠄⢿⣤⣤⣼⡇⠘⣧⣤⣼⠃⠄⢿⡏⠘⣧⡏⠄⣿⠄⠄⢻⡄⢀⠄⠄⠄⠄⢠⣤⣧⣤⡄⠄⠄⠄⠄
// ⠄⠈⠉⠁⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠈⠄⠄⠄⠄⠄⠄⠄⠈⠁⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⢀⡄⠄⠄⠄⠄⠄⠄⣠⠄⠄⠄⠄⠄⠄⠄⠄⣷⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⢀⣤⣤⡄⠄⣠⣤⣤⡄⠄⣤⣠⣤⡄⠄⣤⣠⣤⡄⠄⣠⣤⣤⡀⠰⣶⣷⣶⠄⠄⠄⠠⣶⣿⣶⡆⢀⣤⣤⣤⡄⠄⣿⠄⣠⡦⠄⣠⣤⣤⣄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⡟⠁⠄⠁⢸⡏⠄⢸⡇⠄⣿⠁⠈⡇⢀⣿⠁⠨⡇⢸⡏⠄⢘⡇⠄⠄⣿⠄⠄⠄⠄⠄⠄⣿⠄⠄⣾⠁⠄⢺⠁⢀⣿⠾⣏⠄⢠⣯⠴⠖⠋⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠻⠶⠶⠗⠘⠷⠶⠾⠷⠄⠿⠄⠄⠿⠈⠧⠄⠄⠷⠈⠳⠶⠾⠁⠄⠄⠿⠄⠄⠄⠄⠄⠄⠿⠄⠄⠙⠷⠶⠾⠇⠸⡇⠄⠙⣷⠄⠻⠶⠶⠞⠃⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠄⠄⠄⠄⢀⡀⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠄⣦⠄⠄⢸⡇⠄⠄⠄⠄⠛⠄⠄⠄⢀⡀⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠘⠛⣿⠛⠃⢸⣷⠾⢷⡄⠄⣷⠄⣴⡟⠛⠿⠄⠄⠄⢀⣴⠞⢳⡆⢰⣧⡶⢻⡆⢺⡄⠄⢠⡷⢰⣧⡶⢷⡶⠿⣦⠄⣠⡾⠻⣦⠄⣾⡶⠚⣷⢀⡴⠟⢳⡆⠄⠄⠄⠄⠄
// ⠄⠄⣿⠄⠄⢸⡇⠄⢸⡇⠄⣿⠄⡈⠙⢻⡆⠄⠄⠄⢸⡇⠄⢸⡇⢸⡟⠄⢸⡇⠄⢻⣤⡿⠁⢸⡏⠄⢸⡇⠄⣿⠄⣿⡀⠄⣽⠄⣿⠄⠄⠄⢸⣗⠚⠉⣀⠄⠄⠄⠄⠄
// ⠄⠄⠛⠄⠄⠘⠃⠄⠈⠃⠄⠛⠄⠛⠛⠛⠁⠄⠄⠄⠈⠛⠛⠋⠛⠘⠃⠄⠄⠛⠄⢀⡿⠁⠄⠘⠃⠄⠸⠇⠄⠘⠃⠈⠛⠛⠁⠄⠛⠄⠄⠄⠄⠙⠛⠛⠋⠄⠶⠄⠄⠄
// ⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠾⠃⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄
// ⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄



const GUY_SCRIPT_BASE = "eltrasnag/nide26/npc/people/base.nut"
IncludeScript("eltrasnag/common.nut", this)
IncludeScript("eltrasnag/nide26/misc/guy_names.nut", getroottable())
IncludeScript("eltrasnag/modules/shared.nut", this)
IncludeScript("eltrasnag/nide26/shared.nut", this)
IncludeScript("eltrasnag/nide26/stage2.nut", this)
IncludeScript("eltrasnag/nide26/stage3.nut", this)
IncludeScript("eltrasnag/modules/weaponfunc.nut", getroottable())
IncludeScript("eltrasnag/nide26/shared.nut", this)
IncludeScript("eltrasnag/fmv.nut", this)
IncludeScript("eltrasnag/nide26_edit/pathfollowing.nut", this)
IncludeScript("eltrasnag/nide26/story.nut", this)
IncludeScript("eltrasnag/modules/econstants.nut", this)
IncludeScript("eltrasnag/csrounds.nut", this)
IncludeScript("eltrasnag/nide26/stage2.nut", this)
IncludeScript("eltrasnag/modules/multifog.nut", this)

// make sure this gets included AFTER all the rest
IncludeScript("eltrasnag/nide26/playersettings.nut", this)

// feature ideas :
// - the common cold

// !CompilePal::IncludeDirectory("models/eltra/nide26")




::g_pServerCommand <- Spawn("point_servercommand", {targetname = "cmd", classname = "point_servercommand_kill"})

// Earthbound-style rolling health for humans
::g_bDoRollingHealth <- true;

// Enable sprinting system
::g_bStaminaEnabled <- false;

// can you read
::g_bDoTeeKnockBack <- false;

// TO DO:
// STAGE 1: FINISHED!!!!
// STAGE 2: CHECK PLEASE - MOSTLY FINISHED!!! BROKEN TPS
// STAGE 3: MY THERAPIST SAYS THERE'S STILL A LOT OF WORK TO BE DONE.
 
// POTENTIAL CRASHES WITH ITEMS
// MAYBE CAUSES: - CROWBAR VIEWMODEL. LESHAWNA. PLAYERMODEL.


// equivalent

// !CompilePal::IncludeFile("scripts/vscripts/eltrasnag/nide26/npc/people/base.nut")
// !CompilePal::IncludeFile("scripts/vscripts/eltrasnag/zombieescape/zeitem.nut")
// !CompilePal::IncludeFile("scripts/vscripts/eltrasnag/modules/getdistance.nut")
// !CompilePal::IncludeFile("scripts/vscripts/eltrasnag/modules/ihealth.nut")
// !CompilePal::IncludeFile("scripts/vscripts/eltrasnag/modules/shared.nut")
// !CompilePal::IncludeFile("scripts/vscripts/eltrasnag/modules/econstants.nut")
// !CompilePal::IncludeFile("scripts/vscripts/eltrasnag/nide26/shared.nut")



// !CompilePal::IncludeDirectory("sound/eltra/nide26/")
// !CompilePal::IncludeDirectory("materials/eltra/fmv/nide26")
// !CompilePal::IncludeDirectory("materials/eltra/fmv/logladyintro_frames/")
// !CompilePal::IncludeDirectory("materials/eltra/fmv/end_lores_frames/")


// !CompilePal::IncludeDirectory("materials/eltra/nide26/shaders")
// !CompilePal::IncludeDirectory("materials/eltra/nide26/thedream")
// !CompilePal::IncludeDirectory("sound/music/eltra/nide26")
// !CompilePal::IncludeDirectory("shaders/")

// !CompilePal::IncludeDirectory("scripts/vscripts/eltrasnag/nide26")

// You wont ever rape me again.
enum TEAMS {
	HUMANS = 3,
	ZOMBIES = 2,
	SPECTATORS = 1,
	UNASSIGNED = 0,
}
# FINAL BOSS HEALTH VALUES! STORE HERE FOR EASY ACCESS IF (WHEN) THE MAP NEEDS A STRIPPER FILE
::g_iFinalBossHealthPerPlayer <- 15000
::g_iPrayersPerPlayer <- 5;
::g_iPrayerDamage <- g_iFinalBossHealthPerPlayer/g_iPrayersPerPlayer

::g_bDoApplyCustomWeapons <- false;

point_clientcommand <- Spawn("point_clientcommand", {targetname = "clientcmd"})

const MAP_GRAVITY = 0.75

// // no world can describe how hacky this is
// function __RunScriptHookCallbacks( event, params )
// {
// 	printl("im going to fucking kill you")
// 	__RunEventCallbacks( event, params, "OnScriptHook_", "ScriptHookCallbacks", true )
// }

m_bIsReleaseMap <- false;

// certain variables are only needed when playing on the actual map, so lets make dev time a bit easier
vec_SkyCameraOrigin <- Entities.FindByClassname(null, "sky_camera") != null ? Entities.FindByClassname(null, "sky_camera").GetOrigin() : Vector();
if (GetMapName().find("supersallyworld") != null) {
	::v_BlackZone_hDest <- Entities.FindByName(null, "nothingzone_hdest").GetOrigin();
	::v_BlackZone_zDest <- Entities.FindByName(null, "nothingzone_zdest").GetOrigin();
	m_bIsReleaseMap = true;
} else {
	dprintl("BRO THIS IS NOT FUCKIGN SALLY WORLD")
}


// h_SkyCamera <- Entities.FindByClassname(null, "sky_camera");

::g_pMusicInfoTable <- {
	"super_sally_theme_main" : "Eltra	Super Sally World 346 (Main Theme)"
	"transfer_room" : "Eltra	The Transfer Room"
	"face_space" : "Eltra	Face Space"
	"shaw_theme" : "Eltra	Shaw Elan Orb OC's Theme"
	"leshawnas_theme_pitched" : "Eltra	Leshawna Orb OC's Theme"
	"battery_jam_edit" : "Eltra	Battery Jam"
	"shaw_theme_transfer" : " 	 Help me"
	"pod" : " 	 i literally dont know the name of this one but it is from the wall e pc game from like 2004 whichi  played on my grandma pc at 8 years old"
	"burgeria_drone_voiceoflove" : "Eltra/Angelo Badalamenti	Burgeria Drone/Voice of Love"
	"funkytown_echoes_1" : "Eltra/Lipps Inc.	Funkytown Echoes"
	"scary_stories" : "Eltra	Scary Stories"
	"alien_invasion_nide26" : "Keichii Suzuki	 Alien Invasion (Edit)"
	"spacetilt" : "Eltra	Space Tilt (Part I)"
	"spacetilt_p2" : "Eltra	Space Tilt (Part II)"
	"kill_lois" : "Eltra	KILL LOIS"
	"lesbian_times" : "Eltra	Cool and Lesbian Times."
	"funkytown_credits" : "Eltra/Lipps Inc.	Funkytown (sally mix)"
	"rockinback" : "Julee Cruise	Rockin' Back Inside my Heart"
	"investigations" : "Kevin MacLeod	Investigations"
	"sneakyadventure" : "Kevin MacLeod	Sneaky Adventure"
	"wiffipulsor" : "Eltra	Wiffipulsor"
	"springinmystep" : "Eltra	Spring in My Step"
	"twinpeaks" : "Angelo Badalamenti/David Lynch	Twin Peaks Theme"
	"funnysong" : "BenSound	Funny Song"
	"angel_fire" : "Eltra	AngelFire"
	"space_needle_south" : "Eltra	Space Needle South"
	"addisonpepsi" : "Addison Rae	Diet Pepsi"
}

::MAP_COLOR_HEX <- "FFFFFF"

const PIXEL_OVERLAY_DANGER = "eltra/nide26/shaders/eltra_psx_bleedingout.vmt"
::CIVILIANS_ALIVE <- 0
const SOUND_DIR = "eltra/nide26/"
const PLAYERMODEL_DIR = "models/eltra/nide26/player/"
::CTModels <- ["ct_guest_female.mdl","ct_guest_male.mdl"]
::TModels <- ["t_johndoe.mdl","t_janedoe.mdl"]

STAGE_TEMPLATES <- [ Entities.FindByName(null, "tem_stage1"), Entities.FindByName(null, "tem_stage2"), Entities.FindByName(null, "tem_stage3") ]

enum PREG_SKY { DAY, DESERT, NIGHT, WEB , SPACE}

// StageOrigins <- {
//     "web": Entities.FindByName(null, "sky_web_origin").GetOrigin(),
//     "desert1": Entities.FindByName(null, "s1_sky_origin_desert1").GetOrigin(),
//     "desert2": Entities.FindByName(null, "s2_sky_origin_desert1").GetOrigin(),
// }

m_pSkyProps <- []



::g_bDoItemSpawn <- false;

// PLEASE LET THIS OVERRIDE!!
::SpawnTemplate <- function(template_name) {
	if (template_name == "heal") {
		g_pTemplates.tem_fuckheal.ForceSpawn(caller)
	}
	if (template_name == "tee") {
		g_pTemplates.tem_fucktee.ForceSpawn(caller)
	}

	// if (g_bDoItemSpawn == true) {
	// 	SpawnTemplateEntity(template_name, caller.GetOrigin())
	// }
}

m_pIntroSlideArray <- [];

m_flIntroSlideLength <- 33.0;

// do the map intro
function DoSlidesIntro() {
	PlaySoundGlobal("eltra/nide26/intro_mysteries.mp3")
	PlaySoundGlobal("eltra/nide26/intro_mysteries.mp3", 98)
	local slide_interval = m_flIntroSlideLength/6.0;
	local slide_delay = 0;
	for (local i = 1; i <= 6; i++)
	{
		QFire("player*", "RunScriptCode", "self.SetScriptOverlayMaterial(`"+"eltra/nide26/introslides/introslide"+i+".vmt"+"`)", i * slide_interval, null)
		// slide_delay += slide_interval
	}
}


// ▄▖▜            ▖  ▌         ▜   ▐▘▗   ▗ ▌                ▗▘▄▖▜ ▘    ▗   ▄ ▘              ▗ ▝▖
// ▙▌▐ ▀▌▌▌█▌▛▘   ▌▛▌▛▌▛▌▛▌▌▌  ▐ █▌▜▘▜▘  ▜▘▛▌█▌  ▛▌▀▌▛▛▌█▌  ▐ ▌ ▐ ▌█▌▛▌▜▘  ▌▌▌▛▘▛▘▛▌▛▌▛▌█▌▛▘▜▘ ▌
// ▌ ▐▖█▌▙▌▙▖▌   ▙▌▙▌▌▌▌▌▌▌▙▌  ▐▖▙▖▐ ▐▖  ▐▖▌▌▙▖  ▙▌█▌▌▌▌▙▖  ▐ ▙▖▐▖▌▙▖▌▌▐▖  ▙▘▌▄▌▙▖▙▌▌▌▌▌▙▖▙▖▐▖ ▌
//       ▄▌                ▄▌                    ▄▌         ▝▖                                ▗▘


function CleanSkyboxModels() {
	if (vec_SkyCameraOrigin) {
	foreach (i, prop in m_pSkyProps) {
		if (ValidEntity(prop)) {
			prop.Destroy()
		}
	}
	}
}



::SetVisFilter <- function(player, toggle) {
	printl("visfilter")
	if (toggle == true) {
		ClientPrint(player, EConstants.EHudNotify.HUD_PRINTTALK, "\x07FFFFFFELTRA MAP SETTINGS: CRT Filter has been enabled. Type '!nofilter' to disable it.")
		SetPlayerSetting(player, "m_bNoFilter", false)
		
		return
	}
	ClientPrint(player, EConstants.EHudNotify.HUD_PRINTTALK, "\x07FFFFFFELTRA MAP SETTINGS: CRT Filter has been disabled. Type '!showfilter' to re-enable it.")
	SetPlayerSetting(player, "m_bNoFilter", true)
}

::g_pSettingsFunctions <- {
	"!noflash" : function(player) {
		// TO-DO
	},
	"!showfilter" : function(player) {
		SetVisFilter(player, true)
	}, 
	"!nofilter" : function(player) {
		SetVisFilter(player, false)
	},
	"!adminroom" : function(player) {
		if (GetSteamID(player) == ELTRA_STEAMID) {
			player.SetOrigin(Entities.FindByName(null, "sally_admin_dest").GetOrigin())		
		}
		// TO-DO : Go to admin room
	}
	
}


::MAPSYS_EVENTS <- {OnGameEvent_player_spawn = function(params) {
		printl("\n\n\n\n\n\n I spawned. \n\n\n\n\n\n")
		SpawnFunction(params.userid)
	},

	OnGameEvent_player_say = function(params) {
		local hPlayer = GetPlayerFromUserID(params.userid)
		
		foreach (sz_setting, p_function in g_pSettingsFunctions) {
			if (params.text.tolower().find(sz_setting) != null) {
				p_function.call(this, hPlayer)
			}
		}
		
	}

}


// ::ResetPlayerName <- function(ply) {
// 	if (ply == null || !(ValidEntity(ply))) {
// 		return;
// 	}

// 	ply.ValidateScriptScope()
// 	local pscope = ply.GetScriptScope()

// 	if ("m_szOriginalPlayerName" in pscope && pscope.m_szOriginalPlayerName != null) {
// 		NetProps.SetPropString(ply, "m_szNetname", pscope.m_szOriginalPlayerName)
// 	}
// }
const SALLY_WARNING_ALARM = "eltra/nide26/map_reset_alarm.mp3"
const SALLY_WARNING_MESSAGE = "Super Sally:\nYour game is about to freeze while I reload my AWESOME Sally world!\nDO NOT press your keyboard or your mouse during the freeze!!!\nOr you will crash for real!!!!"

// hack
::g_bDidRoundEnd <- false;
::MAPSYS_EVENTS.OnGameEvent_round_end <- function(params) {
	if (g_bDidRoundEnd == true) {
		return
	}
	::g_bDidRoundEnd <- true;

	ClientPrint(null, 4, SALLY_WARNING_MESSAGE)

	::g_hSallyAlarmSound <- Spawn("ambient_generic", {
		health = 10,
		spawnflags = 49,
		message = SALLY_WARNING_ALARM,
	})

	for (local i=0; i<5; i++) {
		EntFire("worldspawn", "RunScriptCode", "ClientPrint(null, 4, SALLY_WARNING_MESSAGE)", i, null);
		// sally blaring alarm
		EntFireByHandle(g_hSallyAlarmSound, "PlaySound", "", i*2.0+1, null, null);
	}
	
	// for (local ambi; ambi = Entities.FindByClassname(ambi, "ambient_generic");) {
	// 	ambi.AcceptInput("Volume", "0", null, null)
	// }

	EntFire("mapsys", "RunScriptCode", "DoWinnerFMV("+params.winner+")", 0, null)
	// for (local i=0; i<5; i++) {
		
	// 	EntFire("worldspawn", "RunScriptCode", "ClientPrint(null, 4, SALLY_WARNING_MESSAGE)", i, null)
	// 	EntFireByHandle("worldspawn", "RunScriptCode", "", i, null)
	// }
}

::MAPSYS_EVENTS.OnGameEvent_player_death <- function(params) {
	// try { // i dont have time to debug these contest ends in 3 days !!!!!
		// printl("Fuck you Diane")
		
		local ply = GetPlayerFromUserID(params.userid)
		
		if ((ply != null && ply.IsValid()) == false) {
			return;
		}

		ply.SetScriptOverlayMaterial("")

		ply.ValidateScriptScope()


		local pscope = ply.GetScriptScope()

		// ResetPlayerName(ply)


		// ply.EnableDraw()

		// if ("m_hPlayerModel" in pscope) {
		// 	if (ply.GetTeam() == TEAMS.HUMANS) {
		// 		// we have to nullcheck again ???
		// 		if ("m_hPlayerModel" in pscope && ValidEntity(pscope.m_hPlayerModel))
		// 		pscope.m_hPlayerModel.BecomeRagdollOnClient(ply.EyeAngles().Forward() * -999)
		// 		// pscope.m_hPlayerModel.Kill() // above line kills ragdoll anyway
		// 	}
		// }
}

	// CollectEventsInScope(MAPSYS_EVENTS)
__CollectGameEventCallbacks(MAPSYS_EVENTS) // I dont get this .

// function Precache() {
// }


function SpawnSkyboxModel(modelname = "", origin_name = "", origin_offset = Vector()) {
	if (vec_SkyCameraOrigin) {

		local origin_pos = Entities.FindByName(null, origin_name);

		if (modelname.len() == 0 || origin_name == "" || !ValidEntity(origin_pos)) {
			return
		}

		origin_pos = origin_pos.GetOrigin()

		local h_SkyProp = Spawn("prop_dynamic", {
			targetname = "skymodel"
			model = modelname,
			origin = vec_SkyCameraOrigin + (origin_pos*0.0625) + origin_offset,
			disableshadows = true,
			disablereceiveshadows = true,
			// disablereceiveshadows = true,
			disablebonefollowers = true,

		})
		QAcceptInput(h_SkyProp, "TurnOff")
		QFireByHandle(h_SkyProp, "TurnOn")
		m_pSkyProps.append(h_SkyProp)
	}
}

function SetSky(next_int) {

	local l_off
	// Entities.FindByClassname(null, "light_environment").AcceptInput("TurnOff", "", null, null)
	// for (local light; light = Entities.FindByName(light, "light_*");) {
	// 	light.AcceptInput("TurnOff", "", null, null)
	// }
	QFire("light_desert", "TurnOff")



	local switch_delay = 1
	switch (next_int) {
		case PREG_SKY.DAY:
			CleanSkyboxModels()
			SetFog("fog_normal")
			// QFire("dlight_environment", "TurnOff", "", 0)
			// QFire("light_day", "TurnOn", "", 0)
			QFire("light_desert", "TurnOff")
			// SpawnSkyboxModel("models/eltra/nide26/spaceneedle_isol.mdl", "s2_sky_origin_desert1", Vector(1000, 1000,0))

			SetSkyboxTexture("sky_pregnant")
		break;

		case PREG_SKY.NIGHT:
			SetFog("fog_night")
			CleanSkyboxModels()
			SetSkyboxTexture("sky_pregnant_night")
		break;

		case PREG_SKY.DESERT:
			CleanSkyboxModels()
			SetFog("fog_desert")
			// SpawnSkyboxModel("models/eltra/nide26/skybox/sky_desert.mdl", "s2_sky_origin_desert1")
			SetSkyboxTexture("sky_pregnant_desert")
			QFire("light_desert", "TurnOn", "", 0) // hacky way of doing this because 3 lights cant all affect rad light
			// QFire("light_day", "TurnOn", "", 0)
		break;

		case PREG_SKY.SPACE:
			CleanSkyboxModels()
			SetFog("fog_space")
			// QFire("light_day", "TurnOn", "", 0)
			SetSkyboxTexture("sky_pregnant_space")
		break;

		default:
			CleanSkyboxModels()
			SetFog("fog_normal")
			// QFire("light_day", "TurnOn", "", 0)
			SetSkyboxTexture("sky_pregnant")
		break;

		// case PREG_SKY.WEB:
		// 	SetSkyboxTexture("sky_pregnant_network")
		// 	SetSkyboxModel("models/eltra/nide26/skybox/sky_web.mdl", "sky_web_origin")
		// 	QFire("elight_day", "TurnOn", "", switch_delay)
		// break;

	}

	// this is the radiosity switch for static props
	// but let's try without this, for the sake of player crashing

	// for (local p; p = Entities.FindByClassname(p, "player");) {
	// 	point_clientcommand.AcceptInput("Command", "r_radiosity 0", p, p)
	// 	// EntFireByHandle(point_clientcommand,"Command", "r_radiosity 1", 0.5,p, p)
	// 	EntFireByHandle(point_clientcommand,"Command", "r_radiosity 3", 0.05,p, p)
	// }

	// for (local p; p = Entities.FindByName(p, "player");) {
	// }
}

MapFog <- "";

function SetSkyBoxModel(a,d=null) {
	// stupid hack
}

IncludeScript("eltrasnag/nide26/misc/guy_names.nut", this) // the names dictionary

// ::RenamePlayer <- function(ply) {

// 	if (ply.GetTeam() != TEAMS.HUMANS) {
// 		return
// 	}

// 	ply.ValidateScriptScope()
// 	local pscope = ply.ValidateScriptScope()
// 	local truename = NetProps.GetPropString(ply, "m_szNetname")

// 	if (!("m_szOriginalPlayerName" in ascope) || (("m_szOriginalPlayerName" in ascope) && ascope.m_szOriginalPlayerName == null)) {
// 		ascope.m_szOriginalPlayerName <- truename;
// 	}

// 	local randname = RandomArray(GUY_NAMES[RandomInt(0,1)])

// 	printl("ELTRADEV: Player "+ascope.m_szOriginalPlayerName+" has just changed their name to ")
// 	NetProps.SetPropString(ply, "m_szNetname", randname)
// }

::SpawnFunction <- function(userid) {


			local ply = GetPlayerFromUserID(userid)
			ply.SetScriptOverlayMaterial("")
			if (ply == null || !(ValidEntity(ply))) {
				return;
			}

			// ResetPlayerName(ply)


			ply.TerminateScriptScope()
			ply.ValidateScriptScope()
			// ply.AcceptInput("RunScriptFile", "eltrasnag/nide26/player.nut", null, null)
			local pscope = ply.GetScriptScope()
			EntFireByHandle(ply, "RunScriptFile", "eltrasnag/nide26/player.nut", 0, null, null)
			// pscope.IncludeScript("eltrasnag/nide26/player.nut", pscope)
			
			

			// SURELY THIS ISNT GOING TO GIVE ZOMBIES WEAPONS.
			// EnablePlayerWeapons(ply)// FUCK YOU 
			// pscope.SetUp()
			// if ("DoPlayerModel" in pscope) {
			// 	pscope.DoPlayerModel()
			// }
}

const EPILEPSY_WARN_DURATION = 5

// ::SetFog <- function(fog_name) {
// 	MapFog <- fog_name
// 	QFire("env_fog_controller", "turnoff")
// 	QFire(fog_name, "turnon","",0.0)
// 	for (local ply; ply = Entities.FindByClassname(ply, "player");) {
// 		QFireByHandle(ply, "SetFogController", fog_name, 0.1)
// 	}
// 	QFire("player*","setfogcontroller",MapFog)
// }

::g_bDoIntroCutscene <- false;

function OnPostSpawn() {

	// ze_map_say(m_szStripper, 1)
	ClientPrint(null, 3, m_szStripper)
	// make server SHUT THE FUCK UP GOD DAMN
	PrecacheSound("eltra/nide26/player/bloxstep3.mp3")
	PrecacheSound("eltra/nide26/player/bloxstep2.mp3")
	PrecacheSound("eltra/nide26/player/bloxstep1.mp3")
	PrecacheSound("eltra/nide26/player/bloxstep4.mp3")

	g_bDidRoundEnd = false;
	local cached_entity;
	while (cached_entity = Entities.FindByName(cached_entity, "precache*")) {
		// cached_entity.KeyValueFromString("classname", "info_target")
		cached_entity.Kill()
	}
	EntFire("cmd", "Command", "sm_force_shake 1", 0.1, null) // you WILL look at the map shakes and you WILL like it
	EntFire("cmd", "Command", "mp_flashlight 1", 0.1, null) // incase
	
	g_pServerCommand.AcceptInput("Command", "mp_roundtime 60", null, null)
	g_pServerCommand.AcceptInput("Command", "sv_turbophysics 0", null, null)
	

	// also allowing noshake during the final boss would be kind of cheaty

	// STORY.DoStoryScene("hantavirus")
	// SetSky(PREG_SKY.DAY)
	// for (local p_helper; p_helper = Entities.FindByName(p_helper, "playermodel_helper");) {
	// 	p_helper.AcceptInput("ClearParent", "", null, null)
	// 	p_helper.RemoveEFlags(EConstants.FEntityEffects.EF_BONEMERGE_FASTCULL)
	// 	p_helper.RemoveEFlags(EConstants.FEntityEffects.EF_BONEMERGE)
	// 	p_helper.Kill()
	// }
	// EntFire("playermodel_helper*", "Kill", "", 0, null)
	for (local p = null; p = Entities.FindByClassname(p, "player");) {
		p.AcceptInput("RunScriptFile", "eltrasnag/nide26/player.nut", null, null)
		// SpawnFunction(NetProps.GetPropInt(p, "m_iUserID"))
	}

	// QAcceptInput(ply, "RunScriptFile", "eltrasnag/nide26/player.nut")




	AddThinkToEnt(self, "MapThink")

	local intro_delay = 0

	if ( "PermaVars" in getroottable()) { // Entities.FindByName(null, "permavars") != null &&
		// printl("PERMAVARS EXISTS!!!")
		PermaVars.iRoundCount++
	} else {
		dprintl("PERMAVARS DOES NOT EXIST YET!!!!")

		// local pv = Spawn("info_target", {
		//     vscripts = "eltrasnag/nide26/permavars.nut",
		//     targetname = "permavars"
		// })

		getroottable().PermaVars <- {}
		PermaVars.iRoundCount <- 0
		PermaVars.i_MapStage <- 0
		PermaVars.m_bDoFruitSkip <- false
		PermaVars.b_ShowEpilepsyWarning <- true // show this once per stage, except stage 3
		// where we show it ALWAYS

	}

	if (PermaVars.i_MapStage == 0 && g_bDoIntroCutscene == false) {
		PermaVars.i_MapStage <- 1;
	}

	if (developer() > 0)  {

		local worldspawn = Entities.First()
		worldspawn.ValidateScriptScope()
		QFireByHandle(worldspawn, "runscriptfile", "eltrasnag/modules/edict_counter.nut")


		if (m_bIsReleaseMap == true && PermaVars.i_MapStage == 0) {
			PermaVars.i_MapStage = 3
			

		}
		// printl("meow")

		if (GetMapName().find("prefab_room") != null) {
			dprintl("WELCOME TO THE SALLY PREFAB MAP!")
			if (GetListenServerHost() != null) {
				GetListenServerHost().SetOrigin(Entities.FindByName(null, "dev_prefab_dest").GetOrigin());
			}
		}

		if (GetMapName().find("finalboss") != null) {
			PermaVars.i_MapStage = 3
			dprintl("SALLY DEV: Activating final boss devmap stuff....")
			QFire("tem_finalboss", "ForceSpawn" )
			QFire("d_dream_master", "RunScriptCode", "StartDreamIntro()", 0.1)
			QFire("d_dream_master",  "RunScriptCode", "MiniSegment_ReturnPlayersToArena()", 0.5)

			// if (ValidEntity(GetListenServerHost()) && ValidEntity(Entities.FindByName(null, "dev_finalbosstrigger"))) {

			// 	GetListenServerHost().SetAbsOrigin(Entities.FindByName(null, "dev_finalbosstrigger").GetOrigin())
			// }
			return

		} else {
			QFire("dev_finalbosstrigger", "Kill")
		}
	}



	// if (developer() < 1 && PermaVars.i_MapStage == 1) {

	// }

	local EpilepsyWarnTime = 0;

	// do the epilepsy warning
	if (PermaVars.b_ShowEpilepsyWarning == true || PermaVars.i_MapStage == 3) {
		if (PermaVars.i_MapStage < 3) {
			PermaVars.b_ShowEpilepsyWarning = false;
		}

 		QFire("player*", "RunScriptCode", "self.SetScriptOverlayMaterial(`eltra/epilepsy_warning_sally.vmt`)", 0.1)
		QFire("player*", "RunScriptCode", "self.SetScriptOverlayMaterial(``)", EpilepsyWarnTime)
		EpilepsyWarnTime += EPILEPSY_WARN_DURATION
	}

	SetZInfectTime(6 + EpilepsyWarnTime)
	RunScriptCode(self, "TitleCard()", EpilepsyWarnTime)
	RunScriptCode(self, "StageAction(PermaVars.i_MapStage)", 6+EpilepsyWarnTime)
	ze_map_say("*** IF YOU CANNOT TRUE SALLY IMMERSION, TYPE !NOFILTER IN THE CHAT TO DISABLE THE VHS FILTER. ***", 20+EpilepsyWarnTime)
	
	


	// if (PermaVars.iRoundCount == 1 && developer() == 0) {
	// 	intro_delay += DoFMVSequence("logladyintro_frames/logladyintro_frame_", 601, 15, "logladyintro.mp3")

	// }



}

function LogIntro() {
	return DoFMVSequence("logladyintro_new_frames/logladyintro_new_frame_", 1052, 23.97602397602398, "logladyintro.mp3")
}

// !CompilePal::IncludeDirectory("materials/eltra/nide26/titlecard")

function StageAction(mapstage) {
	switch (PermaVars.i_MapStage) {
		case 0: // waiting for players
			AddThinkToEnt(self, null)
			// local logladydelay = LogIntro()
			// ze_map_say("Does this look like Santassination to you")
			ScreenFade(null, 0,0,0,255, 0, -1, FFADE_STAYOUT);
			RunScriptCode(self, "DoSlidesIntro()",3);
			RunScriptCode(self, "CSRounds.RoundWin(EConstants.ECSRoundEndReasons.Game_Commencing)", 36)
			PermaVars.i_MapStage = 1;
			
			// AddThinkToEnt(self, "WaitingThink")

		break;
		case 1: // stage 1
			SetSky(PREG_SKY.DAY)
			RunScriptCode(self, "ze_map_say(` - ` + GetMapName().toupper() + ` -`)" 2)
			RunScriptCode(self, "ze_map_say(`MAP MADE BY ELTRA`)", 5)
			RunScriptCode(self, "ze_map_say(`MOST MUSIC MADE BY ELTRA`)", 7)
			RunScriptCode(self, "ze_map_say(`SOME MODELS MADE BY ELTRA`)", 10)
			RunScriptCode(self, "ze_map_say(`YOU MADE BY ELTRA`)", 13)
			ze_map_say("PLEASE ENJOY THIS SALLY PRODUCTION", 16)
			Entities.FindByName(null, "tem_stage1").AcceptInput("ForceSpawn", "", null, null)


			RunScriptCode(self, "STORY.DoStoryScene(`hantavirus`)",  6)
			QFire("s1_leshawna", "RunScriptCode", "SetFollow(true)",  16)
			QFire("mus_maintheme", "PlaySound", "", 2)
			QFire("s1_randomkeyspawn_1", "PickRandom", 1)
			QFire("s1_sallykeyspawncase", "PickRandom", 1)


		break;
		case 2:
			Stage2_Start()
			DesertAction()
			Entities.FindByName(null, "tem_stage2").AcceptInput("ForceSpawn", "", null, null)


		break;
		case 3: // stage 3 start
			SetSky(PREG_SKY.NIGHT)
			// QFire("s3_sky_1", "Color", "50 50 50")
			Entities.FindByName(null, "tem_stage3").AcceptInput("ForceSpawn", "", null, null)
			// QAcceptInput(STAGE_TEMPLATES[2], "ForceSpawn")
		break;

	}
}



// twin peaks as fruits

FRUIT_INTERVAL <- 13
FRUIT_PROGRESS <- 0
FRUIT_TALKS <- ["Laura Palmer would be apple", "Jamesf would BE: kumquat", "Dale cooper: pomegerate", "BOB!!!!!!!!!!!!!!!: pineapple", "Twinpeaks fruits: Audrey Horne wuold be ...CHERRIES", "Eland palmer date", "Ummm Lucys wife would be e,.. i Tink thats one", "Nadine \"THE\"\" BITCH hurly wouldw be Strawbery", "Okay guys......./ thats all I thnk"]


function TestPeaksSkip() {
	if (PermaVars.m_bDoFruitSkip == true) {
		QFire("s1_fruitskip", "kill")
		ze_map_say("Well i guess you get to skip this part .... You already know the 'drill'.")
		return true
	}
	return false
}

function FruitsPart1() {
	ze_map_say("Twin peaks as fruits")
	QFire("mus_funkytown", "Volume", "0")
	QFire("mus_twinpeaks", "PlaySound")
	local delay = FRUIT_INTERVAL
	FruitTalk()
	for (local i = 1; i <= 4; i++) {
		QFire("s1_fruit"+i, "Open", "", delay)
		if (i < 4) {
			RunScriptCode(self, "FruitTalk()", delay + 2)
		} else {
			

		}
		
		delay += FRUIT_INTERVAL
	}
}

function FruitTalk() {
	ze_map_say(FRUIT_TALKS[FRUIT_PROGRESS])
	FRUIT_PROGRESS++

}

if (!("FRUITS_COMPLETED" in getroottable())) {
	getroottable().FRUITS_COMPLETED <- false
}

function FruitsPart2() {
	if (TestPeaksSkip() == true) {
		return
	}
	FruitTalk()
	local delay = FRUIT_INTERVAL
	for (local i = 5; i <= 8; i++) {
		QFire("s1_fruit"+i, "Open", "", delay)
		RunScriptCode(self, "FruitTalk()", delay + 2)
		delay += FRUIT_INTERVAL
	}
}





// stage 1 & 2 desert stuff

a_CarSpawners <- []
::b_InDesert <- false

function DesertAction() {
	b_InDesert = true
	SetSky(PREG_SKY.DESERT)

	local car_string = "s"+PermaVars.i_MapStage+"_desert_car_spawners"
	local car_spawner;
	while (car_spawner = Entities.FindByName(car_spawner, car_string)) {
		car_spawner.QAcceptInput("RunScriptFile","eltrasnag/nide26/desert_car_spawner.nut")
		car_spawner.ValidateScriptScope()
		local s = car_spawner.GetScriptScope()
		s.Setup()
	}
}
function EnterDesert() {
	RunScriptCode(self, "ze_map_say(`I thnk the biome just changed.`)", 1)
	QFire("mus_funnysong", "FadeOut", "5")
	QFire("mus_funkytown", "PlaySound", "", 3)
	DesertAction()
}

a_Drowners <- []

const PIXEL_OVERLAY_OPILA = @"eltra\nide26\map\shader_water_submerged_opila1"

function OpilaWater(activator, toggle = false) {

	if (P_UTILS.ValidTeam(activator) == false) {
		return
	}

	if (toggle) {
		activator.SetGravity(0.7)
		activator.SetMoveType(MOVETYPE_FLY, MOVECOLLIDE_FLY_BOUNCE) // this is fucked but i htink its funny so its ok
		if (a_Drowners.find(activator) == null) {
			a_Drowners.append(activator)
		}
		activator.SetScriptOverlayMaterial(PIXEL_OVERLAY_DANGER)
	} else {

		activator.SetMoveType(MOVETYPE_WALK, MOVECOLLIDE_DEFAULT)
		activator.SetGravity(MAP_GRAVITY)
		activator.SetScriptOverlayMaterial("")
		if (a_Drowners.find(activator) != null) {
			a_Drowners.remove(a_Drowners.find(activator))
		}
	}
}

::VoidFall <- function(activator) {
	if (P_UTILS.ValidTeam(activator) == false) {
		return
	}
	local flFadeTime = 0.2
	if (activator.GetTeam() == TEAMS.HUMANS) {
		ScreenFade(activator, 0,0,0,255, flFadeTime, 10, FFADE_OUT)
		ClientPrint(activator, EConstants.EHudNotify.HUD_PRINTTALK, "\x07fce80cYou just kept falling, forever....!")
		RunScriptCode(activator, "self.SetOrigin(v_BlackZone_hDest)", flFadeTime)

		RunScriptCode(activator, "self.TakeDamage(99999, 0, self)", 1)
	} else {
		ZTele(activator)
	}

}


function MapThink() {
	foreach (i, ply in a_Drowners) {
		if (P_UTILS.ValidTeam(ply) == false) {
			a_Drowners.remove(ply)
			return
		}

		ScreenFade(ply, 0, 0, 255, 255, 0.25, 0, FFADE_IN)
		if (ply.GetTeam() == TEAMS.HUMANS) {
			ply.TakeDamage(99999, DMG_DROWN, ply)
			continue;
		} else {
			ZTele(ply) // bad idea?
			// ply.TakeDamage(99999999, DMG_DROWN, ply)
		}
		// ply.TakeDamage(100000, DMG_DROWN, ply)
	}
	return 0.5
}

::Rape <- function(activator) {
	if (!ValidEntity(activator) || !activator.IsPlayer()) {
		return
	}
	activator.TakeDamage(99999999, DMG_ALWAYSGIB, activator)
	activator.SetScriptOverlayMaterial("eltra/banban_jumpscare")
	PlaySound("npc/stalker/go_alert2a.wav", activator.GetOrigin())
	QFireByHandle(activator, "RunScriptCode", "if (ValidEntity(self)) { self.SetScriptOverlayMaterial(``) }", 1) // ?
}

const OVERLAY_MARIA = "eltra/face.vmt"
const SOUND_MARIA = "eltra/dinosaur.mp3"

::Maria <- function() {
	PlaySoundGlobal(SOUND_MARIA)
	QFire("player", "RunScriptCode", "self.SetScriptOverlayMaterial(OVERLAY_MARIA)")
	QFire("player", "RunScriptCode", "self.SetMoveType(MOVETYPE_NONE, MOVECOLLIDE_DEFAULT)")
	QFire("player", "sethudvisibility", "0")
	QFire("player", "RunScriptCode", "self.SetScriptOverlayMaterial(``)", 10)
	QFire("player", "sethudvisibility", "1", 10)
	QFire("player", "RunScriptCode", "self.SetMoveType(MOVETYPE_WALK, MOVECOLLIDE_DEFAULT)", 10)

}

function DesertNight() {
	SetSky(PREG_SKY.NIGHT)
}


function EndFruits() {
	ze_map_say("Wow its dark now......", 1)
	ze_map_say("You gusys must be kind of tired and ,,, lowkey .... DEAD AS FUCK ......", 4)
	ze_map_say("Lets go takae a little rest at the  motel :D okay", 9)
	QFire("mus_twinpeaks", "FadeOut", "30")
	PermaVars.m_bDoFruitSkip <- true
}

// stage 1 motel ending
STAGE1_SLEEP_DELAY <- 25

function EndStage1() {

	ze_map_say("*You take a melatonin.*")
	for (local p; p = Entities.FindByClassname(p, "player");) {
		ScreenFade(p, 0,0,0,0, STAGE1_SLEEP_DELAY + 5, 99, FFADE_OUT)
	}

	ze_map_say("*Wow im tired...Im thinking of fallking asleep ........", 2)
	ze_map_say("in "+STAGE1_SLEEP_DELAY + " Seconds zzzzz",5)
	ze_map_say("**Yawn in kawaii way*", (STAGE1_SLEEP_DELAY*0.5) + 5)


	QFire("motel_doors", "Close", "", STAGE1_SLEEP_DELAY + 5)
	QFire("motel_doors", "Lock", "", STAGE1_SLEEP_DELAY + 5.1)

	RunScriptCode(self, "EndStage1_b()", STAGE1_SLEEP_DELAY + 5)


}

b_FailZombieDetection <- false

function EndStage1_b() {
	QFire("s1_motel_ztrigger", "Enable")
	// s1_motel_ztrigger.AcceptInput("Enable", "", null, null)

	RunScriptCode(self, "TestZWin()", 0.5)
	ze_map_say("* you drift off into sleep ...... *")

}


function TestZWin() {
	if (b_FailZombieDetection == false) {
		dprintl("cts should win")
		CSRounds.RoundWin(EConstants.ECSRoundEndReasons.CTs_Win)
		if (PermaVars.i_MapStage < 3) {

			PermaVars.i_MapStage++
		} else  {
			PermaVars.i_MapStage = 1
		}
	} else {
		CSRounds.RoundWin(EConstants.ECSRoundEndReasons.Terrorists_Escaped)
		ClientPrint(null, 3, "ZOMBIES GOT INTO THE HOTEL.... YOU FAILED!!!")
	}
}

DEFAULT_SALLY_INFECT_TIME <- 10;

// do we still use this?

function SetZInfectTime(time = 0) {
	dprintl("ZR INFECT TIME IS SET TO: "+(time+DEFAULT_SALLY_INFECT_TIME))
	QFire("cmd", "Command", "zr_infect_spawntime_max "+(time+DEFAULT_SALLY_INFECT_TIME))
	QFire("cmd", "Command", "zr_infect_spawntime_min "+(time+DEFAULT_SALLY_INFECT_TIME))
}

function RoundWin(win_team) {
	if (win_team == TEAMS.HUMANS) {
		if (PermaVars.i_MapStage < 3) {
			PermaVars.i_MapStage ++
		} else {
			PermaVars.i_MapStage = 0 // reset map if there is a win on stage 3
		}

		// enable the per-stage epilepsy warning
		PermaVars.b_ShowEpilepsyWarning = true
		CSRounds.RoundWin(EConstants.ECSRoundEndReasons.CTs_Win)
	} else {
		// zombies win?
	}
}

// function RoundWin(winning_team) {
// 	local roundparam = Spawn("info_map_parameters", {})

// 	if (winning_team == (TEAMS.HUMANS)) {

// 		QFireByHandle(roundparam, "FireWinCondition", ROUND_END_REASON.CTs_PreventEscape.tostring())



// 		for (local p; p = Entities.FindByClassname(p, "player");) {
// 			if (p.GetTeam() == TEAMS.ZOMBIES) {
// 				// p.TakeDamage(9999999, DMG_DISSOLVE, p)
// 				ClientPrint(p, HUD_PRINTCENTER, "THE ZOMBIES WERE UNABLE TO KILL THE SURVIVORS!")
// 			}
// 		}

// 	}
// 	else {
// 		for (local p; p = Entities.FindByClassname(p, "player");) {
// 			if (p.GetTeam() == TEAMS.HUMANS) {
// 				p.TakeDamage(9999999, DMG_DISSOLVE, p)
// 				ClientPrint(p, HUD_PRINTCENTER, "THE SURVIVORS FAILED TO REACH THE GOAL!")
// 			}
// 		}
// 		QFireByHandle(roundparam, "FireWinCondition", ROUND_END_REASON.Terrorists_Escaped.tostring())
// 	 }
// }

// waiting for players
function WaitingThink() {
	local p;
	while (p = Entities.FindByClassname(p, "player")) {
		if ((p != null)) {
			local t = p.GetTeam()
			if (t != null && (t != TEAMS.SPECTATORS) && (t != TEAMS.UNASSIGNED)) {
				p.SetMoveType(MOVETYPE_NONE, MOVECOLLIDE_DEFAULT)
			}

		}

	}
	return 1
}


const WATER_SPLASH_PATH = "eltra/nide26/watersplash/drown_splash"

function Drown(activator) {
	if (P_UTILS.ValidTeam(activator) != true) {
		return
	}
	activator.KeyValueFromVector("basevelocity", Vector(0,0,9999))
	PlaySoundEX(WATER_SPLASH_PATH + RandomInt(1,5) + ".mp3", activator.GetOrigin())

	if (activator.GetTeam() == TEAMS.HUMANS) {
		activator.TakeDamage(99999, DMG_DROWN, activator)
		dprintl(activator, " drowned")
	}
	else {
		ZTele(activator) // just send them to most recent tp
		// zombie drowned do something here probably!!!
	}
}


function DoEndingFMV() {
	QFire("d_mus*", "Volume", "0")
	local dur = DoFMVSequence("end_lowres_frames/end_lowres_frame_", 2650, 12, "leshawna_ending_fmv.mp3")
	g_bStaminaEnabled = false
	
	for (local ply; ply = Entities.FindByClassname(ply, "player");) {
		NetProps.SetPropFloat(ply, "m_flLaggedMovementValue", 0)
	}

	RunScriptCode(self, "CSRounds.RoundWin(CTs_Win)" , dur)
	RunScriptCode(self, "PermaVars.i_MapStage = 1" , dur)
}


function StartTransitionToFinalBoss() {
	Entities.FindByName(null, "tem_finalboss").AcceptInput("ForceSpawn", "", null, null);

	local hHumanDest = Entities.FindByName(null, "final_boss_dest").GetOrigin();
	local hZombieDest = Entities.FindByName(null, "final_boss_dest_zm").GetOrigin();
	
	ScreenFade(null, 0,0,0,255, 0, -1, FFADE_STAYOUT)
	for (local hPlayer; hPlayer = Entities.FindByClassname(hPlayer, "player");) {
		if (hPlayer.GetTeam() == TEAMS.HUMANS) {
			EntFireByHandle(hPlayer, "AddOutput", "origin "+hHumanDest.ToKVString(), 10, null, null)
			hPlayer.SetAbsOrigin(v_BlackZone_hDest)
		} else if (hPlayer.GetTeam() == TEAMS.ZOMBIES) {
			EntFireByHandle(hPlayer, "AddOutput", "origin "+hZombieDest.ToKVString(), 10, null, null)
			hPlayer.SetAbsOrigin(v_BlackZone_zDest)
		}
		DoEntFire("point_clientcommand", "command", "soundfade 100 10 1 1", 0, hPlayer, null);
	}
	
	QFire("d_dream_master", "CallScriptFunction", "StartDreamIntro", 11, null)
	// RunScriptCode(self, "StartFinalBoss()", 10)
	
}




function SetStage(stage_id) {
	ze_map_say("*** ADMIN ROOM : SETTING MAP TO LEVEL "+stage_id+" ***")
	PermaVars.i_MapStage = stage_id;
	CSRounds.RoundWin(EConstants.ECSRoundEndReasons.Game_Commencing)
}


DoWinnerFMV <- function(winner) {
	if (winner == TEAMS.HUMANS) {
		// EntFire("mapsys", "RunScriptCode")

		local STAGE_STRING = "one"

		if (PermaVars.i_MapStage == 2) {
			STAGE_STRING = "two"
		} else if (PermaVars.i_MapStage == 3) {
			STAGE_STRING = "three"
		}

		local p;
		
		while (p = Entities.FindByClassname(p, "player")) {
			EntFire("point_clientcommand", "Command", "speak \"level "+STAGE_STRING+". clear\"",1, p)
		}
		DoFMVSequence("ctwin1_frames/ctwin1_frame_",116, 23333/1000, "ctwin_fmv.mp3")
	}
	if (winner == TEAMS.ZOMBIES) {
		DoFMVSequence("zmwin1_frames/zmwin1_frame_",40, 8, "zmwin1.mp3")
	}
}


m_szStageCardOverlayName <- ""

// !CompilePal::IncludeFile("sound/music/eltra/nide26/safe_space.mp3")


m_pTitleCardArray <- ["", "eltra/nide26/titlecard/tc_1.vmt","eltra/nide26/titlecard/tc_2.vmt","eltra/nide26/titlecard/tc_3.vmt"]

// majority ripped directly from CiC
function TitleCard() {

	// "titlecard_frostbitten"
	// try {
	local szCardTexture = m_pTitleCardArray[PermaVars.i_MapStage]

	// the only title card which should have this happen is stage 0, which is just a cutscene so
	if (szCardTexture == "") {
		return
	}
	// set player title card
	// QFireByHandle(self,)
	// SetViewControlAll("TitleCamera", true)
	
	Spawn("ambient_generic", {
		targetname = "sf_title"
		message = "eltra/cic_titlecard.mp3",
		health = 100,
		spawnflags = 17
	})

	Spawn("ambient_generic", {
		targetname = "sf_title"
		message = "eltra/cic_titlecard.mp3",
		health = 100,
		spawnflags = 17
	})

	QFire("sf_title", "PlaySound", "", 1)
	QFire("sf_title", "FadeOut", "3", 6)
	QFire("sf_title", "StopSound", "", 6+3)
	QFire("sf_title", "Kill", "", 6+4)

	// local title = Entities.FindByName(null, "TitleCard")
	// title.DisableDraw()
	// local tstr = BRUSHMODELS[aTitleCards[MapStage]]
	// QFireByHandle(title, "RunScriptCode", "SetBrushModel(self, `"+ aTitleCards[MapStage] +"`)", 0.1) // delay this just a little bit so brush can get index

	QFire("player*", "RunScriptCode", "self.SetScriptOverlayMaterial(`"+szCardTexture+"`)")
	QFire("player*", "RunScriptCode", "self.SetScriptOverlayMaterial(``)", 6)
		// Hate
	ScreenFade(null, 0,0,0,255,0.01,1, FFADE_OUT) // INITIAL DARKNESS
	QFireByHandle(self, "RunScriptCode", "ScreenFade(null, 0,0,0,255,0.01,1, FFADE_OUT)", 0.01) // FADING INTO THE TITLE CARD
	// QFireByHandle(title, "RunScriptCode", "self.EnableDraw()", 1)
	QFireByHandle(self, "RunScriptCode", "ScreenFade(null, 0,0,0,255,1,0.01, FFADE_IN)", 1) // FADING INTO THE TITLE CARD
	QFireByHandle(self, "RunScriptCode", "ScreenFade(null, 0,0,0,255,1,0.01, FFADE_OUT)", 5) // FADING TO DARKNESS BEFORE STAGE TELEPORT
	QFireByHandle(self, "RunScriptCode", "ScreenFade(null, 0,0,0,255,1,0, FFADE_IN)", 6) // FADING BACK INTO STAGE


	// frostbite v normal functionality
	// if (XMODE) {
	// 	QFire("sf_title_x", "PlaySound","",0.1)
	// 	QFire("titlecard_frostbitten", "Enable","", 3.0)
		// printl("tst")
		// QFireByHandle(self, "RunScriptCode", "ScreenFade(null, 255,0,0,60,0.25,0.1, 2)", 3.0) // RED FLASH WITH X SOUND
		// MapSay("EXTREEEEMEE!!!!!")
	// } else {
	QFire("sf_title", "PlaySound","",0.1)
	// }



		// QFireByHandle(self, "RunScriptCode", "SetViewControlAll(`TitleCamera`, false)", 6) // DEACTIVATE THE TITLECARD CAMERA
	// } catch (exception) {
		// printl(exception)
	// }
}

::g_szMapTeleport <- ""
::g_vMapTeleport <- Vector();

::UpdateMapTeleports <- function() {
	local h_tele = Entities.FindByName(null, g_szMapTeleport)
	if (ValidEntity(h_tele) == true) {
		g_vMapTeleport = h_tele.GetOrigin()
	}
}

::ZTele <- function(activator) {
	if (ValidEntity(activator)) {
		activator.SetOrigin(g_vMapTeleport)
	}
}

function TeleportTest() {
	dprintl("TELETEST: g_szMapTeleport is "+g_szMapTeleport)
	dprintl("TELETEST: g_vMapTeleport is "+g_vMapTeleport)
}

// !CompilePal::IncludeFile("sound/eltra/explode3.mp3")
// !CompilePal::IncludeFile("sound/eltra/explode4.mp3")
// !CompilePal::IncludeFile("sound/eltra/explode5.mp3")



::DoExplosion <- function(ent) {
	local vOrigin;

	if (type(ent) == "Vector") {
		dprintl("vOrigin is vector")
		vOrigin = ent
	} else if (ValidEntity(ent) == true) {
		dprintl("vOrigin is ent")
		vOrigin = ent.GetCenter()
	}

	DoEffect("e_explosion_1", vOrigin)
	ScreenShake(vOrigin, 1000, RandomFloat(0.12, 0.15), 2, 1024, 0, true)
	PlaySoundEX("eltra/explode"+RandomInt(3,5)+".mp3", vOrigin, 100, RandomInt(95,103), 20000)
}

::ExplodeRemove <- function(ent = null) {
	local hEnt = self
	if (ent != null) {
		hEnt = ent
	}
	
	AddThinkToEnt(hEnt, null)
	DoExplosion(hEnt)

	if (self.GetClassname().find("breakable") == null) {
		hEnt.Kill()
	} else {
		QAcceptInput(hEnt, "Break")
	}
}


// *hopefully* this overrides the legacy CiC Explode() in common.nut... surely !!!!!!!
::Explode <- function(ent= null) {
	local hEnt = self
	
	if (ent != null) {
		hEnt = ent
	}

	DoExplosion(hEnt)
}

::Boom <- Explode