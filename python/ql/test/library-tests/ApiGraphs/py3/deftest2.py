# Subclasses

from flask.views import View #$ use=moduleImport("flask").getMember("views").getMember("View")

class MyView(View): #$ use=moduleImport("flask").getMember("views").getMember("View").getASubclassUse()
    myvar = 45 #$ def=moduleImport("flask").getMember("views").getMember("View").getASubclassUse().getMember("myvar")
    def my_method(self): #$ def=moduleImport("flask").getMember("views").getMember("View").getASubclassUse().getMember("my_method")
        return 3 #$ def=moduleImport("flask").getMember("views").getMember("View").getASubclassUse().getMember("my_method").getReturn()

instance = MyView() #$ use=moduleImport("flask").getMember("views").getMember("View").getASubclassUse().getReturn()

def internal():
    from pflask.views import View #$ use=moduleImport("pflask").getMember("views").getMember("View")
    class IntMyView(View): #$ use=moduleImport("pflask").getMember("views").getMember("View").getASubclassUse()
        my_internal_var = 35 #$ def=moduleImport("pflask").getMember("views").getMember("View").getASubclassUse().getMember("my_internal_var")
        def my_internal_method(self): #$ def=moduleImport("pflask").getMember("views").getMember("View").getASubclassUse().getMember("my_internal_method")
            pass

    int_instance = IntMyView() #$ use=moduleImport("pflask").getMember("views").getMember("View").getASubclassUse().getReturn()