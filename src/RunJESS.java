import jess.*;
public class RunJESS {

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		// TODO Auto-generated method stub
		
		
		
		
		Rete r = new Rete();
		try {
			//Value v = r.executeCommand("(printout t \"a\" crlf)");
			//System.out.println(r.getGlobalContext());
			r.batch("cars.clp");
		} catch (JessException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

	}

}
