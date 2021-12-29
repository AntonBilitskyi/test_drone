import asyncio
from mavsdk import System

from mavsdk.camera import (CameraError, Mode)


async def run():

    drone = System()
    await drone.connect(system_address="udp://:14550")

    print("Waiting for drone to connect...")
    async for state in drone.core.connection_state():
        if state.is_connected:
            print(f"Drone discovered!")
            break

    print("Waiting for drone to have a global position estimate...")
    async for health in drone.telemetry.health():
        if health.is_global_position_ok:
            print("Global position estimate ok")
            break

    print_mode_task = asyncio.ensure_future(print_mode(drone))
    print_status_task = asyncio.ensure_future(print_status(drone))
    running_tasks = [print_mode_task, print_status_task]

    print("Setting mode to 'VIDEO'")
    try:
        await drone.camera.set_mode(Mode.VIDEO)
    except CameraError as error:
        print(f"Setting mode failed with error code: {error._result.result}")

    await asyncio.sleep(2)

    status = True

    while status:
        print("Waiting for drone armed...")
        async for status in drone.telemetry.armed():
            if status:
                print("Drone is armed")
                print("Start video")
                try:
                    await drone.camera.start_video()
                except CameraError as error:
                    print(f"Couldn't record video: {error._result.result}")
                break

        print("Waiting for drone disarmed...")
        async for status in drone.telemetry.armed():
            if not status:
                print("Drone is disarmed")
                status = False
                print("Stop video")
                try:
                    await drone.camera.stop_video()
                except CameraError as error:
                    print(f"Couldn't record video: {error._result.result}")
                break

    for task in running_tasks:
        task.cancel()
        try:
            await task
        except asyncio.CancelledError:
            pass
    await asyncio.get_event_loop().shutdown_asyncgens()


async def print_mode(drone):
    async for mode in drone.camera.mode():
        print(f"Camera mode: {mode}")


async def print_status(drone):
    async for status in drone.camera.status():
        print(status)


if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    loop.run_until_complete(run())
