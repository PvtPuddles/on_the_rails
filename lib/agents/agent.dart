import 'package:flame/components.dart';
import 'package:on_the_rails/components/train/train.dart';

class ControlAgent extends Component with HasGameRef {}

class TrainAgent extends ControlAgent {
  Train? activeTrain;

  static const throttleSpeed = 1 / 3;
}
