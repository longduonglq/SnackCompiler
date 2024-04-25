package chocopy.pa3;

public class RegisterNotFreeException extends RuntimeException {
    public RegisterNotFreeException(String msg)
    {
        super(msg);
    }
}
