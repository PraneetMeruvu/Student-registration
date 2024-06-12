import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import javax.swing.JOptionPane;

public class databaseConnection {
    static String DB_URL = "jdbc:oracle:thin:@castor.cc.binghamton.edu:1521:ACAD111"; // Update the database URL
    static String USER = "KLANKA"; // Update the username
    static String PASS = "Akshay*561999"; // Update the password
    static String JDBC_Driver = "oracle.jdbc.driver.OracleDriver";

    public static Connection connection() {
        try {
            Class.forName(JDBC_Driver);
            System.out.println("Connected");
            return DriverManager.getConnection(DB_URL, USER, PASS);
        } catch (ClassNotFoundException | SQLException e) {
            JOptionPane.showMessageDialog(null, e);
            return null;
        }
    }
}
