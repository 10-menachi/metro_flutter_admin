import 'dart:io';

import 'package:admin/app/models/vehicle_type_model.dart';
import 'package:admin/app/utils/fire_store_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../constant/collection_name.dart';
import '../../../constant/constants.dart';
import '../../../constant/show_toast.dart';

class VehicleTypeScreenController extends GetxController {
  Rx<TextEditingController> vehicleTitle = TextEditingController().obs;
  Rx<TextEditingController> minimumCharge = TextEditingController().obs;
  Rx<TextEditingController> minimumChargeWithKm = TextEditingController().obs;
  Rx<TextEditingController> perKm = TextEditingController().obs;
  Rx<TextEditingController> person = TextEditingController().obs;

  RxList<VehicleTypeModel> vehicleTypeList = <VehicleTypeModel>[].obs;
  Rx<TextEditingController> vehicleTypeImage = TextEditingController().obs;
  // Rx<VehicleTypeModel> vehicleTypeModel = VehicleTypeModel().obs;

  RxString title = "VehicleType".obs;
  RxBool isEnable = false.obs;
  Rx<File> imageFile = File('').obs;
  RxString mimeType = 'image/png'.obs;
  RxBool isLoading = false.obs;
  RxBool isEditing = false.obs;
  RxBool isImageUpdated = false.obs;
  RxString imageURL = "".obs;
  RxString editingId = "".obs;

  @override
  void onInit() {
    getData();
    super.onInit();
  }

  getData() async {
    isLoading(true);
    vehicleTypeList.clear();
    List<VehicleTypeModel> data = await FireStoreUtils.getVehicleType();
    vehicleTypeList.addAll(data);

    isLoading(false);
  }

  setDefaultData() {
    vehicleTitle.value.text = "";
    minimumCharge.value.text = "";
    minimumChargeWithKm.value.text = "";
    vehicleTypeImage.value.clear();

    perKm.value.text = "";
    person.value.text = "";
    isEditing.value = false;
    imageFile.value = File('');
    mimeType.value = 'image/png';
    editingId.value = '';
    isEditing.value = false;
    isImageUpdated.value = false;
    imageURL.value = '';
  }

  Future<void> updateVehicleType() async {
    isLoading.value = true; // Use .value for Obx variables
    String docId = editingId.value;

    try {
      // Ensure that imageFile.value is an XFile instance and has a valid path
      if (imageFile.value.path.isNotEmpty) {
        // Use XFile instead of PickedFile
        XFile imageFileX = XFile(imageFile.value.path);

        // Upload image and get the URL
        String? url = await FireStoreUtils.uploadPic(
          imageFileX, // Pass XFile instead of PickedFile
          "vehicleTypeImage", // Correct the typo "vehicleTyepImage" to "vehicleTypeImage"
          docId,
          mimeType.value,
        );

        // Update vehicle type data
        await FireStoreUtils.updateVehicleType(
          VehicleTypeModel(
            id: docId,
            image: url!,
            isActive: isEnable.value,
            title: vehicleTitle.value.text,
            charges: Charges(
              fareMinimumChargesWithinKm: minimumChargeWithKm.value.text,
              farMinimumCharges: minimumCharge.value.text,
              farePerKm: perKm.value.text,
            ),
            persons: person.value.text,
          ),
        );

        // Fetch updated data
        await getData();
      }
    } catch (e) {
      print("Error updating vehicle type: $e");
    } finally {
      isLoading.value = false; // Ensure loading status is updated
    }
  }

  Future<void> addVehicleType() async {
    isLoading.value = true; // Use .value for Obx variables
    String docId = Constant.getRandomString(20);

    try {
      if (imageFile.value.path.isNotEmpty) {
        // Use XFile instead of PickedFile
        XFile imageFileX = XFile(imageFile.value.path);

        // Upload image and get the URL
        String? url = await FireStoreUtils.uploadPic(
          imageFileX, // Pass XFile instead of PickedFile
          "vehicleTypeImage", // Correct the typo "vehicleTyepImage" to "vehicleTypeImage"
          docId,
          mimeType.value,
        );

        // Add vehicle type data
        await FireStoreUtils.addVehicleType(
          VehicleTypeModel(
            id: docId,
            image: url!,
            isActive: isEnable.value,
            title: vehicleTitle.value.text,
            charges: Charges(
              fareMinimumChargesWithinKm: minimumChargeWithKm.value.text,
              farMinimumCharges: minimumCharge.value.text,
              farePerKm: perKm.value.text,
            ),
            persons: person.value.text,
          ),
        );

        // Fetch updated data
        await getData();
      }
    } catch (e) {
      print("Error adding vehicle type: $e");
    } finally {
      isLoading.value = false; // Ensure loading status is updated
    }
  }

  removeVehicleTypeModel(VehicleTypeModel vehicleTypeModel) async {
    isLoading = true.obs;
    await FirebaseFirestore.instance
        .collection(CollectionName.vehicleType)
        .doc(vehicleTypeModel.id)
        .delete()
        .then((value) {
      ShowToastDialog.toast("VehicleType deleted...!".tr);
    }).catchError((error) {
      ShowToastDialog.toast("Something went wrong".tr);
    });
    await getData();
    isLoading = false.obs;
  }
}
