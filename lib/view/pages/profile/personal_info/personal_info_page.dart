import "package:khabroom/utils/responsive.dart";
import "package:khabroom/view/pages/profile/personal_info/personal_info_controller.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final PersonalInfoController c = PersonalInfoController();

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(U.s.personalInformation)),
    body: SingleChildScrollView(
      padding: AppResponsive.pagePadding(context),
      child: AppContent(
        maxWidth: AppResponsive.readableMaxWidth,
        child: Form(
          key: c.formKey,
          child: AppCard(
            child: UColumn(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                UTextField(labelText: U.s.firstName, controller: c.controllerFirstName, validator: UValidators.minLength(message: U.s.thisFieldIsInvalid, minLength: 2)),
                const SizedBox(height: 12),
                UTextField(labelText: U.s.lastName, controller: c.controllerLastName, validator: UValidators.minLength(message: U.s.thisFieldIsInvalid, minLength: 2)),
                const SizedBox(height: 12),
                UTextField(
                  labelText: U.s.nationalCode,
                  controller: c.controllerNationalCode,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  validator: UValidators.iranianNationalCode(invalidMessage: U.s.theEnteredNationalCodeIsIncorrect),
                ),
                const SizedBox(height: 12),
                UTextField(labelText: U.s.email, controller: c.controllerEmail, keyboardType: TextInputType.emailAddress, validator: UValidators.email(isRequired: false)),
                const SizedBox(height: 20),
                UButton(title: U.s.saveChanges, fullWidth: true, onTap: c.submit),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
