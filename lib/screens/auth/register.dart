import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String selectedRole = "Buyer";
  bool hidePassword = true;
  bool hideConfirmPassword = true;

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Create Account"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(20),

        child: Form(

          key: _formKey,

          child: Column(

            children: [

              const Icon(
                Icons.person_add_alt_1,
                size: 90,
                color: Color(0xff0A4D68),
              ),

              const SizedBox(height: 15),

              const Text(
                "Join MaarinLink",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              DropdownButtonFormField<String>(

                value: selectedRole,

                decoration: const InputDecoration(
                  labelText: "Register As",
                  prefixIcon: Icon(Icons.people),
                  border: OutlineInputBorder(),
                ),

                items: const [

                  DropdownMenuItem(
                    value: "Buyer",
                    child: Text("Buyer"),
                  ),

                  DropdownMenuItem(
                    value: "Exporter",
                    child: Text("Fish Exporter"),
                  ),

                ],

                onChanged: (value){
                  setState(() {
                    selectedRole = value!;
                  });
                },
              ),

              const SizedBox(height: 20),

              TextFormField(

                controller: passwordController,

                obscureText: hidePassword,

                decoration: InputDecoration(

                  labelText: "Password",

                  prefixIcon: const Icon(Icons.lock),

                  suffixIcon: IconButton(

                    icon: Icon(
                      hidePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),

                    onPressed: (){
                      setState(() {
                        hidePassword = !hidePassword;
                      });
                    },
                  ),

                  border: const OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(

                controller: confirmPasswordController,

                obscureText: hideConfirmPassword,

                decoration: InputDecoration(

                  labelText: "Confirm Password",

                  prefixIcon: const Icon(Icons.lock_outline),

                  suffixIcon: IconButton(

                    icon: Icon(
                      hideConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),

                    onPressed: (){
                      setState(() {
                        hideConfirmPassword = !hideConfirmPassword;
                      });
                    },
                  ),

                  border: const OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(

                width: double.infinity,

                height: 55,

                child: ElevatedButton(

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0A4D68),
                  ),

                  onPressed: (){

                    // TODO:
                    // Save user in MongoDB

                  },

                  child: const Text(
                    "REGISTER",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              TextButton(

                onPressed: (){
                  Navigator.pop(context);
                },

                child: const Text("Already have an account? Login"),

              ),

            ],
          ),
        ),
      ),
    );
  }
}